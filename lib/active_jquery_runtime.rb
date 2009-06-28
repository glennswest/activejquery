require 'rubygems'
require 'pp'

class ActiveJqueryRuntime
def initialize(table,ctlenv)
   @controller = ctlenv.params[:controller]
   @url = @controller
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
   @tabledef = table.inspect.split(/[:,()]/)
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
        end
   if @hasnamefield == TRUE
      @selectfield = "name"
     else 
      @selectfield = @firstfield
     end
   @tableheading = @controller.humanize()
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

   # Add the javascripts for the associated tables
   @associations.each {|myassoc|
       themacro = myassoc.macro.to_s
       thetable = myassoc.class_name
       case themacro
          when "has_many"
                @jqgrid_html << '<script src="' + thetable.downcase + '.js?subof=' + @tablename + 
                                '&div=' + @tablename + '_' + thetable + 
                                '" type="text/javascript"></script>' + "\n"
          when "has_one"
                @jqgrid_html << '<script src="' + thetable.downcase + '.js?subof=' + @tablename + 
                               '&div=' + @tablename + '_' + thetable + 
                               '&gridtype=localsel' + 
                               '" type="text/javascript"></script>' + "\n"
          end
       }
   self.html_generate(@tablename)
   @associations.each {|myassoc|
       themacro = myassoc.macro.to_s
       thetable = myassoc.class_name
       if themacro == "has_many"
          self.html_generate(@tablename + '_' + thetable)
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
   @jqgrid_html << '<div id="' + divid + '-pager" class="scroll"' + '></div>' + "\n"
   @jqgrid_html << '<table id="' + divid + '" class="scroll" style="text-align:left;"></table>' + "\n"
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

def jqgrid_generate(divid='list',thetable,subtable,parent,gridtype)
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
  @jqgrid_str << "   editurl: " + divid + "_editurl,\n"
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
  @jqgrid_str << "   pager: jQuery('#" + divid + "-pager'),\n"
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
  @jqgrid_str << "   autowidth: true,\n"
  #@jqgrid_str << '   toolbar: [true,"top"],' + "\n"
  @jqgrid_str << "   sortname: 'id',\n"
  @jqgrid_str << '   sortorder: "desc",' + "\n"
  @jqgrid_str << '   editData: {authenticity_token:authenticityToken},' + "\n"
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
  @jqgrid_str << ".navGrid('#" + divid + "-pager'," +
                 '{viewrecords:false,'
  if @edit == TRUE
     @jqgrid_str << 'add:true,del:true,'
     end
  @jqgrid_str << 'search:true,view:true});' + "\n"
  @jqgrid_str << "});\n"
end



end

