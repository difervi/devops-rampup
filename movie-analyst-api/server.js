// Get our dependencies
const express = require('express')
const app = express()
const mysql = require('mysql')
const util = require('util')
const path = require('path')

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'applicationuser',
  password: process.env.DB_PASS || 'applicationuser',
  database: process.env.DB_NAME || 'movie_db'
})
pool.query = util.promisify(pool.query)

// Configure EJS views to serve the UI from the bundled movie-analyst-ui folder
// When running inside the Docker image the UI is included under ./movie-analyst-ui
const uiViews = path.join(__dirname, 'movie-analyst-ui', 'public', 'views')
const uiPublic = path.join(__dirname, 'movie-analyst-ui', 'public')
app.set('view engine', 'ejs')
app.set('views', uiViews)
app.use(express.static(uiPublic))

// Implement the movies API endpoint
app.get('/movies', async function (req, res) {
  try {
    const rows = await pool.query(
      'select m.title, m.release_year, m.score, r.name as reviewer, p.name as publication from movies m,' +
      'reviewers r, publications p where r.publication=p.name and m.reviewer=r.name'
    )
    // If client prefers HTML, render the EJS template; otherwise return JSON (API clients)
    if (req.accepts('html')) {
      return res.render('movies', { movies: rows })
    }
    return res.json(rows)
  } catch (err) {
    console.error('API Error:', err)
    if (req.accepts('html')) {
      return res.status(500).render('index', { error: 'Internal server error' })
    }
    res.status(500).send({ msg: 'Internal server error' })
  }
})

app.get('/reviewers', async function (req, res) {
  try {
    const rows = await pool.query('select r.name, r.publication, r.avatar from reviewers r')
    if (req.accepts('html')) {
      // render the authors view which expects `authors` variable
      return res.render('authors', { authors: rows })
    }
    res.json(rows)
  } catch (err) {
    console.error('API Error:', err)
    if (req.accepts('html')) {
      return res.status(500).render('index', { error: 'Internal server error' })
    }
    res.status(500).send({ msg: 'Internal server error' })
  }
})

// Provide a convenience route /authors that matches the UI routes
app.get('/authors', function (req, res) {
  // delegate to the existing /reviewers handler by making an internal request
  req.url = '/reviewers'
  return app._router.handle(req, res)
})

app.get('/publications', async function (req, res) {
  try {
    const rows = await pool.query('select name from publications')
    if (req.accepts('html')) {
      return res.render('publications', { publications: rows })
    }
    res.json(rows)
  } catch (err) {
    console.error('API Error:', err)
    if (req.accepts('html')) {
      return res.status(500).render('index', { error: 'Internal server error' })
    }
    res.status(500).send({ msg: 'Internal server error' })
  }
})

app.get('/pending', async function (req, res) {
  try {
    const rows = await pool.query(
      'select m.title, m.release, m.score, r.name as reviewer, p.name as publication' +
      'from movie_db.movies m, movie_db.reviewers r, movie_db.publications p where' +
      'r.publication=p.name and m.reviewer=r.name and m.release>=2017'
    )
    if (req.accepts('html')) {
      return res.render('index', { pending: rows })
    }
    res.json(rows)
  } catch (err) {
    console.error('API Error:', err)
    if (req.accepts('html')) {
      return res.status(500).render('index', { error: 'Internal server error' })
    }
    res.status(500).send({ msg: 'Internal server error' })
  }
})

app.get('/', function (req, res) {
  if (req.accepts('html')) {
    return res.render('index')
  }
  res.status(200).send({ service_status: 'Up' })
})

console.log('server listening through port: ' + process.env.PORT)
app.listen(process.env.PORT || 3000)
module.exports = app
