module Searchable
  def self.included(base)
    def base.searchable_on(*args)
      @searchable_attrs = args
    end

    def base.catalog_search(query)
      if query.blank? # if the string is blank, return all
        active
      else # in all other cases, search using the query text
        results = []
        # search each query word on each attribute specified via searchable_on
        query.split.each do |q|
          query_results = []
          @searchable_attrs.each do |attribute|
            query_results << active.where("#{attribute} LIKE :query", query: "%#{q}%")
          end
          # remove duplicate items in case they were added more than once
          # e.g. a term match in both name and description results in an item being added twice
          query_results.uniq!
          # flatten all elements associated with one query word into a 1D array
          query_results.flatten!
          # add this array to the over-all results
          results << query_results
        end
        # take the intersection of the results for each word
        # i.e. choose results matching all terms
        results.inject(:&)
      end
    end
  end
end
