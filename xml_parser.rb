require 'active_support'

class Parser

  def initialize
    @unique_entities = []
    @created_tables = {}
  end

  def print_unique_entities
    puts "List of unique entities:"
    @unique_entities.each_with_index do |e, i|
      puts "  #{i}: #{e.camelize}"
    end
    puts "End of list of entities"
  end

  def find_elements_and_nested(node)
    result = {
      elements: [],
      nested: []
    }

    node.keys.each do |key|
      if node[key].class == Hash || node[key].class == Array
        @unique_entities << key unless @unique_entities.include? key
        result[:nested] << key
      else
        result[:elements] << key
      end
    end
    result
  end

  def generate_migration(model, attributes = nil, parent = nil, namespace = nil)
    return if model.nil?

    cmd = ''
    if namespace
      cmd = "rails g model #{namespace.downcase}/#{model.underscore.downcase.camelize}"
    else
      cmd = "rails g model #{model.underscore.downcase.camelize}"
    end
    attributes.each { |a| cmd << " #{a.underscore}:string" } if attributes
    if namespace
      cmd << " #{namespace.downcase}_#{parent.tableize}:references" if parent
    else
      cmd << " #{parent.tableize}:references" if parent
    end
    @created_tables[model] = true
    system(cmd)
    cmd
  end

  def append_associations(node, node_name = nil, parent = nil, namespace = nil)
    log = ''

    dir = "./app/models/"

    dir += "#{namespace.downcase}/" if namespace

    attributes = find_elements_and_nested(node)

    attributes[:nested].each do |key|
      if node[key].class == Array
        node[key].each { |n| log += create_tables n, key, node_name, namespace }
      else
        log += create_tables node[key], key, node_name, namespace
      end
    end
    @created_tables = {} unless parent #problematic
    log
  end

  def create_tables(node, node_name = nil, parent = nil, namespace = nil)
    log = ''

    attributes = find_elements_and_nested(node)

    log += "  #{generate_migration(node_name, attributes[:elements], parent, namespace)}\n\n" unless @created_tables[node_name]

    attributes[:nested].each do |key|
      if node[key].class == Array
        node[key].each { |n| log += create_tables n, key, node_name, namespace }
      else
        log += create_tables node[key], key, node_name, namespace
      end
    end
    @created_tables = {} unless parent #problematic
    log
  end

  def save_data(node, node_name, parent = nil, namespace = nil)
    log = "\nclass #{node_name.underscore.downcase.camelize}\n"

    attributes = find_elements_and_nested(node)
    model_create = ''
    
    if namespace
      model_create = "\n  ##{namespace.downcase.capitalize}::#{node_name.try(:camelize)}.create"
    else
      model_create = "\n  ##{node_name.try(:camelize)}.create"
    end

    attributes[:elements].each do |key|
      if namespace
        model_create += " #{namespace.downcase}_#{key.underscore}: \"#{node[key]}\","
      else
        model_create += " #{key.underscore}: \"#{node[key]}\","
      end
      log += "  ##{key.underscore} => \"#{node[key]}\"\n"
    end

    model_create = model_create[0...-1] if model_create[model_create.size-1] == ','
    if namespace
      model_create += ", #{namespace}_#{parent.underscore}_id: #{namespace.downcase.capitalize}::#{node_name.try(:camelize)}.last" if parent
    else
      model_create += ", #{parent.underscore}_id: #{parent.camelize}.last" if parent
    end

    #eval model_create

    log += model_create + "\n"

    log += "end\n" unless node_name.nil?

    attributes[:nested].each do |key|
      if node[key].class == Array
        node[key].each { |n| log += save_data n, key, node_name, namespace }
      else
        log += save_data node[key], key, node_name, namespace
      end
    end
    log

  end

  def traverse_nodes(node, node_name = nil, parent = nil)
    log = ''
    log = "\nclass #{node_name.underscore.downcase.camelize}\n" unless node_name.nil?

    attributes = find_elements_and_nested(node)

    log += "  #{generate_migration(node_name, attributes[:elements], parent)}\n\n"

    log += "  belongs_to :#{parent.tableize.singularize}\n" unless parent.nil?

    #system("rails g model #{node_name.camelize} [elements:string] parent:references")
    attributes[:nested].each do |key|
      if node[key].class == Array
        log += "  has_many :#{key.tableize}\n"
      else
        log += "  have_one :#{key.tableize.singularize}\n"
      end
    end
    log += "\n"

    model_create = "\n  ##{node_name.try(:camelize)}.create"
    attributes[:elements].each do |key|
      model_create += " #{key.underscore}: \"#{node[key]}\","
      log += "  ##{key.underscore} => \"#{node[key]}\"\n"
    end

    model_create = model_create[0...-1] if model_create[model_create.size-1] == ','
    model_create += ", #{parent.underscore}_id: #{parent.camelize}.last" if parent

    log += model_create + "\n"

    log += "end\n" unless node_name.nil?

    attributes[:nested].each do |key|
      if node[key].class == Array
        node[key].each { |n| log += traverse_nodes n, key, node_name }
      else
        log += traverse_nodes node[key], key, node_name
      end
    end
    log
  end
end
