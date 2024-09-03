from flask import Flask, jsonify
from datetime import datetime
import pytz

app = Flask(__name__)

@app.route('/time', methods=['GET'])
def get_current_time():
    current_time = datetime.now(pytz.utc)
    return jsonify({
        "current_time": current_time.isoformat()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)