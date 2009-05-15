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
   @edittype = :inplace
   if @actions.include?(:create) or @actions.include?(:update)
     @edit = TRUE
     end
    
   @columns = Hash.new
   @table = table
   @tabledef = table.inspect.split(/[:,()]/)
   @tabledef.each {|theitem|
         theitem.lstrip!
         }
   mydef = Array.new(@tabledef)
   @tablename = mydef.shift
   while !mydef.empty?()
         cname = mydef.shift
         ctype = mydef.shift
         @columns[cname] = Hash.new
         @columns[cname]["name"] = cname
         @columns[cname]["type"] = ctype
         @columns[cname]["hidden"] = FALSE
         @columns[cname]["label"] = cname.humanize
         @columns[cname]["listok"] = TRUE
         if cname == "id"
           @columns[cname]["key"] = TRUE
           @columns[cname]["editable"] = FALSE
          else
           @columns[cname]["key"] = FALSE
           @columns[cname]["editable"] = @edit
          end
        end
          
   @tableheading = @controller.humanize()
   self.jqgrid_generate()
   self.html_generate()
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
                user_params[key] = value
                end
          end
          }
    return user_params
end

def grid_html()
    return(@jqgrid_html)
end


def html_generate(divid = 'list')
   @jqgrid_html = String.new
   @jqgrid_html << '<div id="' + divid + '-pager" class="scroll"' + '></div>' + "\n"
   @jqgrid_html << '<table id="' + divid + '" class="scroll" style="text-align:left;"></table>' + "\n"
end

def grid_javascript()
    return(@jqgrid_str)
end

def jqgrid_generate(divid='list')
  @jqgrid_str = String.new
  @jqgrid_str << '<script type="text/javascript">' + "\n"
  if @edit == TRUE
     if @edittype == :inplace
        @jqgrid_str << "var " + divid + "lastsel;\n"
        @jqgrid_str << "var editurl;\n"
        @jqgrid_str << "var extraparam = {};\n"
        @jqgrid_str << "extraparam = {authenticity_token:authenticityToken};\n"
        @jqgrid_str << "myediturl = '" + @url + 
                       "' + '?authenticity_token=' + authenticityToken;\n"
        end
     end
  @jqgrid_str << 'jQuery(document).ready(function(){' + "\n"
  @jqgrid_str << 'jQuery("#' + divid + '").jqGrid({' + "\n"
  @jqgrid_str << "   url:'" + @url + ".xml" +"',\n"
  @jqgrid_str << "   editurl: myediturl,\n"
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
         when 'string'
              @jqgrid_str << "width:300,align:'left',"
              if @columns[cname]["editable"]
                 @jqgrid_str << "editable:true,"
                else
                 @jqgrid_str << "editable:false,"
                end
              #@jqgrid_str << "edittype:" + '"' + @columns[cname]["edittype"] + '"' + ","
         when 'integer'
              @jqgrid_str << "width:80,align:'right',"
         when 'datetime'
              # <created-on type="datetime">2008-08-18T07:00:24Z</created-on>
              @jqgrid_str << "width:130,"
        end
    @jqgrid_str.chop! # Get rid of trailing comma
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
        @jqgrid_str << "     if(id && id!==" + divid + "lastsel){\n"
        @jqgrid_str << "        jQuery('#" + divid + "').restoreRow(" + divid + "lastsel);\n"
        @jqgrid_str << "         " + divid + "lastsel=id;\n"
        @jqgrid_str << "         }\n"
        @jqgrid_str << "     jQuery('#" + divid + "').editRow(id,true);\n"
        @jqgrid_str << "     },\n"
        end
     end
#
  @jqgrid_str << "   rowNum:10,\n"
  @jqgrid_str << "   autowidth: true,\n"
  @jqgrid_str << '   toolbar: [true,"top"],' + "\n"
  #@jqgrid_str << "   rowList:[10,20,30],\n"
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
  @jqgrid_str << "                repeatitems:false\n"
  @jqgrid_str << "},\n"
  @jqgrid_str << "  });\n"
  @jqgrid_str << 'jQuery("#' + divid + '")' + ".navGrid('#" + divid + "-pager'," +
                 '{viewrecords:false,add:true,del:true,search:true });' + "\n"
  @jqgrid_str << "});\n"
  @jqgrid_str << "</script>\n"
end



end

