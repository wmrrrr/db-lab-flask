from flask import Flask, send_from_directory
from instagram.auth.controller.user_controller import user_bp
from instagram.auth.route import init_routes

# Swagger UI
from flask_swagger_ui import get_swaggerui_blueprint

app = Flask(__name__)

# ----------------------- SWAGGER SERVE OPENAPI FILE -------------------------
@app.route('/openapi.yml')
def openapi():
    # шукає файл openapi.yml у тій же папці, де main.py
    return send_from_directory('.', 'openapi.yml')

# ----------------------- SWAGGER UI CONFIG -----------------------------------
SWAGGER_URL = "/api-docs"
API_URL = "/openapi.yml"

swaggerui_blueprint = get_swaggerui_blueprint(
    SWAGGER_URL,
    API_URL,
    config={"app_name": "DB Lab API"}
)

app.register_blueprint(swaggerui_blueprint, url_prefix=SWAGGER_URL)

# ----------------------- YOUR ROUTES -----------------------------------------
init_routes(app)

# ----------------------- RUN APP ---------------------------------------------
if __name__ == '__main__':
    app.run(debug=True)
