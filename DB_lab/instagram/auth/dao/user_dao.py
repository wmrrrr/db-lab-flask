
import pymysql
class UserDAO:
    def __init__(self, db):
        self.db = db

    def get_all_users(self):
        cursor = self.db.cursor()
        query = "SELECT id, name, email FROM users"  
        cursor.execute(query)
        users = cursor.fetchall()
        cursor.close()
        return users

    def get_user_by_id(self, user_id):
        cursor = self.db.cursor()
        query = "SELECT id, name, email FROM users WHERE id = %s"
        cursor.execute(query, (user_id,))
        user = cursor.fetchone()
        cursor.close()
        return user

    def insert_user(self, name, email, password):
        try:
            cursor = self.db.cursor()
            query = "INSERT INTO users (name, email, password) VALUES (%s, %s, %s)"
            cursor.execute(query, (name, email, password))
            self.db.commit()
            cursor.close()
        except Exception as e:
            self.db.rollback()
            raise e

    def update_user(self, user_id, name=None, email=None, password=None):
        try:
            cursor = self.db.cursor()
            query = "UPDATE users SET "
            fields = []
            values = []

            if name:
                fields.append("name = %s")
                values.append(name)

            if email:
                fields.append("email = %s")
                values.append(email)

            if password:
                fields.append("password = %s")
                values.append(password)

            if fields:
                query += ", ".join(fields) + " WHERE id = %s"
                values.append(user_id)
                cursor.execute(query, tuple(values))
                self.db.commit()
            cursor.close()
        except Exception as e:
            self.db.rollback()
            raise e

    def delete_user(self, user_id):
        try:
            cursor = self.db.cursor()
            query = "DELETE FROM users WHERE id = %s"
            cursor.execute(query, (user_id,))
            self.db.commit()
            cursor.close()
            return {'message': 'User deleted successfully!'}, 204
        except Exception as e:
            self.db.rollback()
            raise e

    def get_user_courses(self, user_id):
        cursor = self.db.cursor()
        query = ("""
            SELECT courses.id, courses.title, courses.description
            FROM enrollments
            JOIN courses ON enrollments.course_id = courses.id
            WHERE enrollments.user_id = %s
        """)
        cursor.execute(query, (user_id,))
        courses = cursor.fetchall()
        cursor.close()
        return courses
    
  
    def get_all_users_with_courses(self):
        cursor = self.db.cursor()
        sql = """
           SELECT users.id AS user_id, users.name, users.email,
            courses.id AS course_id, courses.title AS course_name, courses.description
            FROM users
            LEFT JOIN enrollments ON users.id = enrollments.user_id
            LEFT JOIN courses ON enrollments.course_id = courses.id
            ORDER BY users.id
            

        """
        try:
            cursor.execute(sql)
            data = cursor.fetchall()
        except pymysql.err.OperationalError as e:
            print(f"Error occurred: {e}")
            cursor.close()
            raise
        cursor.close()
        return data

    def get_user_progress(self, user_id):
        cursor = self.db.cursor()
        query = ("""
            SELECT modules.title, progress.status
            FROM progress
            JOIN modules ON progress.module_id = modules.id
            WHERE progress.user_id = %s
        """)
        cursor.execute(query, (user_id,))
        progress = cursor.fetchall()
        cursor.close()
        return progress
    
    
    def call_insert_noname_records_procedure(self):
        """Виклик процедури InsertNonameRecords"""
        try:
            cursor = self.db.cursor()
            cursor.callproc('InsertNonameRecords')
            self.db.commit()
        except Exception as e:
            self.db.rollback()
            raise e
        finally:
            cursor.close()