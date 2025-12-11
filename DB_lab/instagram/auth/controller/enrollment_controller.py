from flask import Blueprint, jsonify, request
from ..service.enrollment_service import EnrollmentService
from ..dao.enrollment_dao import EnrollmentDAO
from config.config import Config
import pymysql

enrollment_bp = Blueprint('enrollment', __name__)

config = Config()
db = pymysql.connect(host=config.DB_HOST,
                     user=config.DB_USER,
                     password=config.DB_PASSWORD,
                     database=config.DB_NAME)

enrollment_dao = EnrollmentDAO(db)
enrollment_service = EnrollmentService(enrollment_dao)  # Тут передається enrollment_dao

@enrollment_bp.route('/enrollments', methods=['GET'])
def get_enrollments():
    enrollments = enrollment_service.get_all_enrollments()
    return jsonify(enrollments), 200

@enrollment_bp.route('/enrollments', methods=['POST'])
def add_enrollment():
    data = request.json
    user_id = data.get('user_id')   
    course_id = data.get('course_id')
    completion_status = data.get('completion_status')

    enrollment_service.add_enrollment(user_id, course_id, completion_status)
    return jsonify({'message': 'Enrollment added successfully!'}), 201

@enrollment_bp.route('/enrollments/<int:enrollment_id>', methods=['DELETE'])
def delete_enrollment(enrollment_id):
    enrollment_service.delete_enrollment(enrollment_id)
    return jsonify({'message': 'Enrollment deleted successfully!'}), 204



@enrollment_bp.route('/enrollments/by-names', methods=['POST'])
def add_enrollment_by_names():
    data = request.json

    # Перевірка обов'язкових полів
    if not all(key in data for key in ('user_name', 'course_title', 'enrollment_date', 'completion_status')):
        return jsonify({'error': 'Missing required fields: user_name, course_title, enrollment_date, completion_status'}), 400

    user_name = data['user_name']
    course_title = data['course_title']
    enrollment_date = data['enrollment_date']
    completion_status = data['completion_status']

    try:
        # Виклик методу в сервісі
        enrollment_service.add_enrollment_by_names(user_name, course_title, enrollment_date, completion_status)
        return jsonify({'message': 'Enrollment added successfully by names!'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500