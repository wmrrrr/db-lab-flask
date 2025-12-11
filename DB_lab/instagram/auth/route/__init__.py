from instagram.auth.controller.user_controller import user_bp
from  instagram.auth.controller.enrollment_controller import enrollment_bp
from instagram.auth.controller.review import review_bp
from instagram.auth.controller.statistic import statistic_bp
from instagram.auth.controller.table_controller import table_bp
def init_routes(app):
    app.register_blueprint(user_bp)
    app.register_blueprint(enrollment_bp)
    app.register_blueprint(review_bp)
    app.register_blueprint(statistic_bp)
    app.register_blueprint(table_bp)