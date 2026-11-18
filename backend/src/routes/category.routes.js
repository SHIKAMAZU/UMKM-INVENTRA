import { Router } from 'express';
import {
  createCategory,
  deleteCategory,
  getCategory,
  listCategories,
  updateCategory,
} from '../controllers/category.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import { idParamSchema } from '../validators/common.validator.js';
import {
  createCategoryBodySchema,
  updateCategoryBodySchema,
} from '../validators/category.validator.js';

const router = Router();

router.use(authenticate);

router.get('/', listCategories);
router.get('/:id', validate({ params: idParamSchema }), getCategory);
router.post('/', authorize('admin'), validate({ body: createCategoryBodySchema }), createCategory);
router.put(
  '/:id',
  authorize('admin'),
  validate({ params: idParamSchema, body: updateCategoryBodySchema }),
  updateCategory
);
router.delete('/:id', authorize('admin'), validate({ params: idParamSchema }), deleteCategory);

export default router;
