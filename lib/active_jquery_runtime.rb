require 'rubygems'
require 'pp'

class ActiveJqueryRuntime
def find_associated_fields(assoc)
   assoc_columns = Array.new
   @associations.each {|myassoc|
       themacro = myassoc.macro.to_s
       thetable = myassoc.class_name
       thename  = myassoc.name.to_s
       assoc_columns << thename
       assoc_columns << themacro
       }
   return(assoc_columns)
end

def initialize(table,ctlenv)
   @controller = ctlenv.params[:controller]
   @url = "/" + @controller # To handle namespace properly
   @tkey = "id"
   @actions = [:create, :update, :show, :delete, :search]
   @edit = FALSE
   @editmodes = [:inplace,:form]
   @jqgrid_html = String.new
   #@edittype = :inplace
   @edittype = :form
   if @actions.include?(:create) or @actions.include?(:update)
     @edit = TRUE
     end
    
   @columns = Hash.new
   @table = table
   @associations = table.reflect_on_all_associations
   @assoc_fields = find_associated_fields(@associations)
   @tabledef = table.inspect.split(/[:,()]/)
   @tabledef.concat(@assoc_fields)
   @tabledef.each {|theitem|
         theitem.lstrip!
         }
   mydef = Array.new(@tabledef)
   @tablename = mydef.shift
   @firstfield = ""
   @hasnamefield = FALSE
   @selectfield = ""
   while !mydef.empty?()
         cname = mydef.shift
         ctype = mydef.shift
         @columns[cname] = Hash.new
         @columns[cname]["name"] = cname
         @columns[cname]["type"] = ctype
         @columns[cname]["hidden"] = FALSE
         @columns[cname]["label"] = cname.humanize
         @columns[cname]["listok"] = TRUE
         @columns[cname]["is_association"] = FALSE
         if @firstfield == ""
            if cname != "id"
               @firstfield = cname    
               end
            end
         case cname
           when "name"
             @hasnamefield = TRUE
             @columns[cname]["key"] = FALSE
             @columns[cname]["editable"] = TRUE
             @columns[cname]["hidden"] = FALSE
           when "id"
             @columns[cname]["key"] = TRUE
             @columns[cname]["editable"] = FALSE
             @columns[cname]["hidden"] = TRUE
           when "created_at"
             @columns[cname]["key"] = FALSE
             @columns[cname]["editable"] = FALSE
             @columns[cname]["hidden"] = TRUE
           when "updated_on"
             @columns[cname]["key"] = FALSE
             @columns[cname]["editable"] = FALSE
             @columns[cname]["hidden"] = TRUE
           when "updated_at"
             @columns[cname]["key"] = FALSE
             @columns[cname]["editable"] = FALSE
             @columns[cname]["hidden"] = TRUE
           else
             @columns[cname]["key"] = FALSE
             @columns[cname]["editable"] = @edit
             end
       if cname[-3,3] == "_id" # We have a reference to a index
          thename = cname[0..-4]
          @columns[cname]["hidden"] = TRUE
          @columns[cname]["editable"] = FALSE
          # Add a string field to take the 'name' into the grid
          @columns[thename] = Hash.new
          @columns[thename]["name"] = thename
          @columns[thename]["type"] = 'string'
          @columns[thename]["hidden"] = FALSE
          @columns[thename]["editable"] = TRUE
          @columns[thename]["label"] = thename.humanize
          @columns[thename]["listok"] = TRUE
          @columns[thename]["related_field"] = cname
          end      
        end
   if @hasnamefield == TRUE
      @selectfield = "name"
     else 
      @selectfield = @firstfield
     end
   @tableheading = @controller.humanize()
   self.html_generate(@tablename)
   end

def gen_associations()
#
# Example:
#
#@associations=
#  [#<ActiveRecord::Reflection::AssociationReflection:0x14e48e0
#    @active_record=
#     Company(id: integer, name: string, created_at: datetime, updated_at: datetime),
#    @macro=:has_many,
#    @name=:user,
#    @options={:extend=>[]}>,
#   #<ActiveRecord::Reflection::AssociationReflection:0x14e3b48
#    @active_record=
#     Company(id: integer, name: string, created_at: datetime, updated_at: datetime),
#    @macro=:has_many,
#    @name=:location,
#    @options={:extend=>[]}>,
#   #<ActiveRecord::Reflection::AssociationReflection:0x14d8a90
#    @active_record=
#     Company(id: integer, name: string, created_at: datetime, updated_at: datetime),
#    @macro=:has_many,
#    @name=:division,
#    @options={:extend=>[]}>],
#<ActiveRecord::Reflection::AssociationReflection:0x274a728
# @active_record=
#  User(id: integer, name: string, email: string, supervisor_id: integer, company_id: integer, division_id: integer, department_id: integer, location_id: integer, created_at: datetime, updated_at: datetime),
# @class_name="User",
# @macro=:has_one,
# @name=:supervisor,
# @options={:class_name=>"User"}>


   # Add the javascripts for the associated tables
   @associations.each {|myassoc|
       themacro = myassoc.macro.to_s
       thetable = myassoc.class_name
       thename  = myassoc.name.to_s
       theid = thename.downcase + "_id"
       if @columns.has_key?(theid)   # We have a key to association
          @columns[theid]["is_association"] = TRUE
          @columns[theid]["association_name"] = thename
          @columns[theid]["association_table"] = thetable
          @columns[theid]["association_type"] = themacro
          end
       case themacro
          when "has_many"
                @jqgrid_html << '<script src="' + thetable.downcase + '.js?subof=' + thetable + 
                                '&div=' + thename + '_' + thetable + 
                                '" type="text/javascript"></script>' + "\n"
          when "has_one"
                @jqgrid_html << '<script src="' + thetable.downcase + '.js?subof=' + thetable + 
                               '&div=' + thename + '_select' + 
                               '&gridtype=localsel' + 
                               '" type="text/javascript"></script>' + "\n"
          end
       }
   @associations.each {|myassoc|
       themacro = myassoc.macro.to_s
       thetable = myassoc.class_name
       thename  = myassoc.name.to_s
       case themacro
       when "has_many"
          self.html_generate(thename + '_' + thetable)
       when "has_one"
          self.html_generate(thename + '_select')
          end
       }
end

def filter_for_create(my_params)
    # For now, treat as a update
    user_parms = filter_for_update(my_params)
    return user_parms
end

def filter_for_update(my_params)
    user_params = Hash.new
    my_params.each {|key,value|
          if @columns.has_key?(key)   # We have that param as a column
             if @columns[key]["editable"]
                case @columns[key]["type"]
                 when 'boolean'
                   case value
                       when 'on'
                          user_params[key] = true
                       when 'off'
                          user_params[key] = false
                       end
                 else
                  user_params[key] = value
                  end
                end
          end
          }
    return user_params
end

def grid_html()
    return(@jqgrid_html)
end


def html_generate(divid = 'list')
   @jqgrid_html << '<table id="' + divid + '"></table>' + "\n"
   @jqgrid_html << '<div id="' + divid + '_pager"' + '></div>' + "\n"
end

def grid_javascript(myparams)
    divid = @tablename
    tablename = @tablename
    parenttable = @tablename
    subtable = FALSE
    # Grid Types
    # main = standard grid
    # localselect = used for selecting a record, with the result stored in javascript
    gridtype = "main"
    if myparams.has_key?("gridtype")
       gridtype = myparams["gridtype"]
       end 
    if myparams.has_key?("div")
       divid = myparams["div"]
       end
    if myparams.has_key?("subof")
       subtable = TRUE
       parenttable = myparams["subof"]
       end
    jqgrid_generate(divid,tablename,subtable,parenttable,gridtype)
    return(@jqgrid_str)
end

def jqgrid_generate(divid,thetable,gsubtable,gparent,gridtype)
  @jqgrid_str = String.new
  case gridtype
     when "main"
     when "localsel"
          @edit = FALSE
     end
  if @edit == TRUE
     @jqgrid_str << "var " + divid + "_editurl;\n"
     @jqgrid_str << divid + "_editurl = '" + @url + 
                       "' + '?authenticity_token=' + encodeURIComponent(authenticityToken);\n"
     if @edittype == :inplace
        @jqgrid_str << "var " + divid + "_lastsel;\n"
        end
     end
  @jqgrid_str << 'jQuery(document).ready(function(){' + "\n"
  @jqgrid_str << 'jQuery("#' + divid + '").jqGrid({' + "\n"
  @jqgrid_str << "   url:'" + @url + ".xml" +"',\n"
  if @edit
     @jqgrid_str << "   editurl: " + divid + "_editurl,\n"
     end
  @jqgrid_str << "   datatype: 'xml', \n"
  @jqgrid_str << "   height: " + '"auto"' + ", \n"
  @jqgrid_str << "   mtype: 'GET',\n"
  @jqgrid_str << '   colNames:['
  @columns.each_key { |cname|
      @jqgrid_str << "'" + @columns[cname]["label"] + "',"
     }
  @jqgrid_str.chop!
  @jqgrid_str << "],\n"
  @jqgrid_str << "   colModel :[\n"
  @columns.each_key { |cname|
     @jqgrid_str << "      "
     @jqgrid_str << "{name: '" + @columns[cname]["name"] + "',"
     @jqgrid_str <<  "index:'" + @columns[cname]["name"] + "',"
     if @columns[cname]["key"]
        @jqgrid_str << "key:true,"
       else
        @jqgrid_str << "key:false,"
       end
     case @columns[cname]["type"]
         when 'boolean'
              @jqgrid_str << "width:80,align:'left',edittype:'checkbox'," +
                             "formatter:'checkbox',"
         when 'string'
              @jqgrid_str << "width:300,align:'left',"
         when 'integer'
              @jqgrid_str << "width:80,align:'right',"
         when 'datetime'
              # <created-on type="datetime">2008-08-18T07:00:24Z</created-on>
              @jqgrid_str << "width:180,"
        end
     case gridtype
        when 'main'
             if @columns[cname]["hidden"]
                @jqgrid_str << "hidden:true,"
               else
                @jqgrid_str << "hidden:false,"
              end
             if @columns[cname]["editable"]
                @jqgrid_str << "editable:true"
               else
                @jqgrid_str << "editable:false"
               end
        when 'localsel'
             if cname == @selectfield 
                @jqgrid_str << "hidden:false,"
               else
                @jqgrid_str << "hidden:true,"
               end
             @jqgrid_str << "editable:false"
        end    
    @jqgrid_str << "},\n"
    }
  @jqgrid_str.chomp!
  @jqgrid_str.chop!
  @jqgrid_str << "],\n"
  @jqgrid_str << "   pager: jQuery('#" + divid + "_pager'),\n"
#
# In Place Editing
#
  if @edit == TRUE
     if @edittype == :inplace
        @jqgrid_str << "   onSelectRow: function(id){\n"
        @jqgrid_str << "     if(id && id!==" + divid + "_lastsel){\n"
        @jqgrid_str << "        jQuery('#" + divid + "').restoreRow(" + divid + "_lastsel);\n"
        @jqgrid_str << "         " + divid + "_lastsel=id;\n"
        @jqgrid_str << "         }\n"
        @jqgrid_str << "     jQuery('#" + divid + "').editRow(id,true);\n"
        @jqgrid_str << "     },\n"
        end
     end
#
  @jqgrid_str << "   rowNum:10,\n"
  case gridtype
     when 'main'
          @jqgrid_str << "   autowidth: true,\n"
     when 'localsel'
          select_name = divid
          function_name = divid + "_dataInit"
          @jqgrid_str << "  " + function_name + ' : function  ( elem ) { ' + "\n"
          @jqgrid_str << "      $('#gbox_" + divid + "').show();\n"
          @jqgrid_str << "      },\n"
     end

       
  #@jqgrid_str << '   toolbar: [true,"top"],' + "\n"
  @jqgrid_str << "   sortname: 'id',\n"
  @jqgrid_str << '   sortorder: "desc",' + "\n"
  if @edit
     @jqgrid_str << '   editData: {authenticity_token:authenticityToken},' + "\n"
     end
  @jqgrid_str << '   viewrecords: true,' + "\n"
  @jqgrid_str << "   imgpath: 'javascripts/jqGrid/themes/redmond/images',\n"
  @jqgrid_str << "   caption: '" + @tableheading + "',\n"
  @jqgrid_str << "   xmlReader: {"
  @jqgrid_str <<                 'root: "root",' + "\n"
  @jqgrid_str << '                row: "' + @tablename.downcase + '",' + "\n"
  @jqgrid_str << '                page:"root>page",' + "\n"
  @jqgrid_str << '                total:"root>total",' + "\n"
  @jqgrid_str << '                records:"root>records",' + "\n"
  @jqgrid_str << "                repeatitems:false}\n"
  @jqgrid_str << "  })"
  @jqgrid_str << ".navGrid('#" + divid + "_pager'," +
                 '{viewrecords:false,'
  if @edit == TRUE
     @jqgrid_str << 'add:true,del:true,'
    else
     @jqgrid_str << 'add:false,del:false,'
     end
  @jqgrid_str << 'search:true,view:true});' + "\n"
  case gridtype
       when 'localsel'
            @jqgrid_str << "$('#gbox_" + divid + "').hide();\n"
            # @jqgrid_str << "$('#" + divid + "_pager').hide();\n"
       end
  @jqgrid_str << "});\n"
end



end

