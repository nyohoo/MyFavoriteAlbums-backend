module ApplicationHelper
  def paginate(query, page, per_page)
    query.page(page).per(per_page)
  end
end