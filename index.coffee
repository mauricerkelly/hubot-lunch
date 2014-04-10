fs = require 'fs'
path = require 'path'

module.exports = (robot, scripts) ->
  srcPath = path.resolve(__dirname, 'src')
  fs.exists srcPath, (exists) ->
    if exists
      for script in fs.readdirSync(srcPath)
        if scripts? and '*' not in scripts
          robot.loadFile(srcPath, script) if script in scripts
        else
          robot.loadFile(srcPath, script)
