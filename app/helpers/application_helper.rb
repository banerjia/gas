module ApplicationHelper
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s + "/" + association.to_s.singularize + "_fields", :f => builder)
    end
    return raw "<a onclick='add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")'>#{name}</a>"
  end

  def branch_info
    branch_name = `git rev-parse --abbrev-ref HEAD`
  end

end
