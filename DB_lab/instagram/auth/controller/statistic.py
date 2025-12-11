# controllers/statistic_controller.py

from flask import Blueprint, jsonify, request
from instagram.auth.dao.statistic import StatisticDAO
from instagram.auth.service.statistic import StatisticService
from config.config import Config
import pymysql

statistic_bp = Blueprint('statistic', __name__)

# Ініціалізація підключення до бази даних
config = Config()
db = pymysql.connect(host=config.DB_HOST,
                     user=config.DB_USER,
                     password=config.DB_PASSWORD,
                     database=config.DB_NAME)

# Ініціалізація DAO і Service
statistic_dao = StatisticDAO(db)
statistic_service = StatisticService(statistic_dao)

@statistic_bp.route('/statistics', methods=['GET'])
def get_statistic():
    """Отримати статистику через процедуру CallStatisticFunction"""
    stat_type = request.args.get('type')
    if stat_type not in ('MAX', 'MIN', 'SUM', 'AVG'):
        return jsonify({'error': 'Invalid statType. Use MAX, MIN, SUM, or AVG.'}), 400

    try:
        # Виклик сервісу для отримання статистики
        result = statistic_service.get_statistic(stat_type)
        return jsonify({'StatisticResult': result[0][0]}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
