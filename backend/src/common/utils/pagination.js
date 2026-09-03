function getPagination(page = 1, limit = 20) {
    const parsedPage = Number(page);
    const parsedLimit = Number(limit);
  
    const safePage =
      Number.isInteger(parsedPage) && parsedPage > 0
        ? parsedPage
        : 1;
  
    const safeLimit =
      Number.isInteger(parsedLimit) &&
      parsedLimit > 0 &&
      parsedLimit <= 100
        ? parsedLimit
        : 20;
  
    return {
      page: safePage,
      limit: safeLimit,
      skip: (safePage - 1) * safeLimit,
    };
  }
  
  function createPaginationMeta(page, limit, total) {
    const totalPages =
      total === 0 ? 0 : Math.ceil(total / limit);
  
    return {
      page,
      limit,
      total,
      totalPages,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1 && totalPages > 0,
    };
  }
  
  module.exports = {
    getPagination,
    createPaginationMeta,
  };