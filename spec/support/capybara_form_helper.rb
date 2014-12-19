## Load code after Capybara
# see http://minimul.com/submitting-a-form-without-a-button-using-capybara.html
module Capybara
  module Driver
    class Node
      def submit_form!
        fail NotImplementedError
      end
    end
  end

  module RackTest
    class Node
      def submit_form!
        Capybara::RackTest::Form.new(driver, native).submit({})
      end
    end
  end

  module Node
    class Element
      delegate :submit_form!, to: :base
    end
  end
end
