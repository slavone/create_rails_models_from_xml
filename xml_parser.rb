require 'active_support'

class Parser

  def initialize
    @unique_entities = []
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

  def generate_migration(model, attributes = nil, parent = nil)
    return if model.nil?

    cmd = "#rails g model #{model.camelize}"
    attributes.each { |a| cmd << " #{a.underscore}:string" } if attributes
    cmd << " #{parent.camelize}:references" if parent
    cmd
  end

  def write_into(file_name, hash)
    File.open("#{file_name}.rb", 'w') { |file| file << traverse_nodes(hash) }
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
