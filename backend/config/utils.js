import dotenv from 'dotenv';
dotenv.config();

const PORT = process.env.PORT;
const REDIS_URL = process.env.REDIS_URL;
const MYSQL_HOST = process.env.MYSQL_HOST || '127.0.0.1';
const MYSQL_PORT = process.env.MYSQL_PORT || '3306';
const MYSQL_USER = process.env.MYSQL_USER || 'wanderlust_user';
const MYSQL_PASSWORD = process.env.MYSQL_PASSWORD || '';
const MYSQL_DATABASE = process.env.MYSQL_DATABASE || 'wanderlust';

export { PORT, REDIS_URL, MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE };
