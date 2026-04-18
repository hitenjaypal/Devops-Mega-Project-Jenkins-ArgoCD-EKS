import { Sequelize } from 'sequelize';
import { MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE } from './utils.js';

const sequelize = new Sequelize(MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD, {
  host: MYSQL_HOST,
  port: parseInt(MYSQL_PORT) || 3306,
  dialect: 'mysql',
  logging: false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000,
  },
  dialectOptions:
    process.env.NODE_ENV === 'production'
      ? { ssl: { rejectUnauthorized: true } }
      : {},
});

export async function connectDB() {
  try {
    await sequelize.authenticate();
    await sequelize.sync({ force: false });
    console.log(`MySQL database connected: ${MYSQL_HOST}:${MYSQL_PORT || 3306}/${MYSQL_DATABASE}`);
  } catch (err) {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  }
}

export default sequelize;
