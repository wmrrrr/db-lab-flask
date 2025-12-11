import yaml


class Config:
    def __init__(self, config_file='config/app.yml'):
        with open(config_file, 'r') as file:
            config_data = yaml.safe_load(file)

        db_config = config_data.get('db', {})
        self.DB_HOST = db_config.get('host')
        self.DB_USER = db_config.get('user')
        self.DB_PASSWORD = db_config.get('password')
        self.DB_NAME = db_config.get('database')

