import { Router } from 'express';
import { login, me, register } from '../controllers/auth.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { loginBodySchema, registerBodySchema } from '../validators/auth.validator.js';

const router = Router();

router.post('/register', validate({ body: registerBodySchema }), register);
router.post('/login', validate({ body: loginBodySchema }), login);
router.get('/me', authenticate, me);

export default router;
