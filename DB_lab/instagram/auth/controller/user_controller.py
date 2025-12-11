import pymysql
from flask import Blueprint, request, jsonify

from config.config import Config
from instagram.auth.dao.user_dao import UserDAO
from instagram.auth.dto.user_dto import UserDTO, CourseDTO, ProgressDTO
from instagram.auth.service.user_service import UserService
 


user_bp = Blueprint('user', __name__)

config = Config()
db = pymysql.connect(host=config.DB_HOST,
                     user=config.DB_USER,
                     password=config.DB_PASSWORD,
                     database=config.DB_NAME)

# Initialize the User DAO and Service
user_dao = UserDAO(db)
user_service = UserService(user_dao)

@user_bp.route('/users', methods=['GET'])
def get_users():
    users = user_service.get_all_users()
    user_dtos = [UserDTO(user[0], user[1], user[2]).to_dict() for user in users]    
    return jsonify(user_dtos), 200

@user_bp.route('/users', methods=['POST'])
def create_user():
    data = request.json
    username = data['name']
    email = data['email']
    password = data['password']
    user_service.insert_user(username, email, password)
    return jsonify({'message': 'User created successfully!'}), 201

@user_bp.route('/users/<int:user_id>', methods=['GET'])
def get_user_by_id(user_id):
    user = user_service.get_user_by_id(user_id)
    if user:
        user_dto = UserDTO(user[0], user[1], user[2]).to_dict()
        return jsonify(user_dto), 200
    return jsonify({'message': 'User not found'}), 404

@user_bp.route('/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    data = request.json
    username = data.get('name')
    email = data.get('email')   
    password = data.get('password')

    user_service.update_user(user_id, name=username, email=email, password=password)
    return jsonify({'message': 'User updated successfully!'}), 200

@user_bp.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    response, status_code = user_service.delete_user(user_id)
    return jsonify(response), status_code

