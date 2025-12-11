import pymysql
from flask import Blueprint, request, jsonify

from config.config import Config
from instagram.auth.dao.review import ReviewDAO

review_bp = Blueprint('review', __name__)

# Ініціалізація підключення до бази даних
config = Config()
db = pymysql.connect(host=config.DB_HOST,
                     user=config.DB_USER,
                     password=config.DB_PASSWORD,
                     database=config.DB_NAME)

# Ініціалізація DAO
review_dao = ReviewDAO(db)

@review_bp.route('/reviews', methods=['POST'])
def insert_review():
    
    data = request.get_json()

    # Перевірка обов'язкових полів
    if not all(key in data for key in ('course_id', 'user_id', 'rating', 'comment')):
        return jsonify({'error': 'Missing required fields: course_id, user_id, rating, comment'}), 400

    
    course_id = data['course_id']
    user_id = data['user_id']
    rating = data['rating']
    comment = data['comment']

    try:
        review_dao.call_insert_review_procedure(course_id, user_id, rating, comment)
        return jsonify({'message': 'Review inserted successfully!'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500
