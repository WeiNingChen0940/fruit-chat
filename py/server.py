from flask import Flask, send_file, abort
import os
app = Flask(__name__)


@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    try:
        # 假设文件存在于 'path/to/files' 目录下
        current_directory = os.getcwd()
        file_path = f'{current_directory}\\files\\{filename}'
        return send_file(file_path, as_attachment=True)
    except FileNotFoundError:
        abort(404)


if __name__ == '__main__':
    app.run(host='172.16.91.233', port=5000)
