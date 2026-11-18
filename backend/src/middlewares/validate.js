import { AppError } from '../utils/AppError.js';

function formatIssues(error) {
  return error.issues.reduce((acc, issue) => {
    const path = issue.path.join('.') || '_';
    acc[path] = issue.message;
    return acc;
  }, {});
}

export const validate = (schemas) => (req, res, next) => {
  try {
    const validated = {};
    for (const key of ['params', 'query', 'body']) {
      if (!schemas[key]) continue;
      const result = schemas[key].safeParse(req[key] ?? {});
      if (!result.success) {
        throw new AppError(422, 'Validasi gagal', formatIssues(result.error));
      }
      validated[key] = result.data;
    }
    req.validated = validated;
    next();
  } catch (err) {
    next(err);
  }
};
