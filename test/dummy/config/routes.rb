Rails.application.routes.draw do
  mount QuickSearchArchivesSpaceSearcher::Engine => "/quick_search-archives_space_searcher"
end
