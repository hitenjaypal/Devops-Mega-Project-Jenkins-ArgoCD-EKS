import compression from 'compression';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import express from 'express';
import { connectDB } from './config/db.js';
import { PORT } from './config/utils.js';
import authRouter from './routes/auth.js';
import postsRouter from './routes/posts.js';
import { connectToRedis } from './services/redis.js';

// Import models to register them with Sequelize before sync
import './models/user.js';
import './models/post.js';

const app = express();
const port = PORT || 5000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(cookieParser());
app.use(compression());

// API routes
app.use('/api/posts', postsRouter);
app.use('/api/auth', authRouter);

app.get('/', (req, res) => {
  res.send('Yay!! Backend of wanderlust prod app is now accessible');
});

async function startServer() {
  await connectDB();
  connectToRedis();
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
}

startServer();

export default app;
