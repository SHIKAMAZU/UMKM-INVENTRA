import { Router } from 'express';
import { listUsers } from '../controllers/user.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { userQuerySchema } from '../validators/user.validator.js';

const router = Router();

router.use(authenticate);

router.get('/', authorize('admin'), validate({ query: userQuerySchema }), listUsers);

export default router;
