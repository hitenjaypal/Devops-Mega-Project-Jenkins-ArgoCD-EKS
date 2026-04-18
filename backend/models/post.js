import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const Post = sequelize.define(
  'Post',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    authorName: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    title: {
      type: DataTypes.STRING(500),
      allowNull: false,
    },
    imageLink: {
      type: DataTypes.STRING(500),
      allowNull: false,
    },
    categories: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    isFeaturedPost: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    timeOfPost: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: 'posts',
    timestamps: false,
  }
);

export default Post;
