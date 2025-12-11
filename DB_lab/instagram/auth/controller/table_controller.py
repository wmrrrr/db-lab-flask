# controllers/table_controller.py

from flask import Blueprint, request, jsonify
from instagram.auth.dao.table_dao import TableDAO
from instagram.auth.service.table import TableService
from config.config import Config
import pymysql

table_bp = Blueprint('table', __name__)

# Ініціалізація підключення до бази даних
config = Config()
db = pymysql.connect(host=config.DB_HOST,
                     user=config.DB_USER,
                     password=config.DB_PASSWORD,
                     database=config.DB_NAME)

# Ініціалізація DAO і Service
table_dao = TableDAO(db)
table_service = TableService(table_dao)

@table_bp.route('/tables/distribute', methods=['POST'])
def distribute_data():
    """Виклик процедури CreateAndDistributeData"""
    data = request.get_json()

    # Перевірка обов'язкових параметрів
    if not all(key in data for key in ('parent_table', 'new_table1', 'new_table2')):
        return jsonify({'error': 'Missing required fields: parent_table, new_table1, new_table2'}), 400

    parent_table = data['parent_table']
    new_table1 = data['new_table1']
    new_table2 = data['new_table2']

    try:
        # Виклик сервісу
        table_service.create_and_distribute_data(parent_table, new_table1, new_table2)
        return jsonify({'message': 'Data distributed successfully!'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500
