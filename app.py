from flask import Flask
from flask import render_template
import argparse
import os
import socket

app = Flask(__name__)

color_codes = {
    'blue':   '#7ac8ee',
    'green':  '#9eff9a',
    'pink':   '#f6019d',
    'purple': '#541388',
    'red':    '#d24a27',
    'yellow': '#ffca05'
}

@app.route('/')
def hello():
  return render_template('index.html', hostname="workshop",color=color_codes[COLOR])

@app.route("/color")
def color():
    return "Hostname: {} ; Color: {}".format(HOSTNAME, COLOR)

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument('-c', '--color', default='red', required=False)
  args = parser.parse_args()

  # check for envvar 'COLOR'
  if os.environ.get('COLOR'):
    COLOR = os.environ.get('COLOR')
  # check for cmdline arg '--color'; overwrites envvar if set
  elif args.color:
    COLOR = args.color
  # no color found, default to 'red'
  else:
    COLOR = 'red'

  # check for invalid input
  if COLOR not in color_codes:
    print("Invalid color " + COLOR)
    exit(1)

  # get hostname
  HOSTNAME = socket.gethostname()

  app.run(host='0.0.0.0', port=80)