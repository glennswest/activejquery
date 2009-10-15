require 'active_jquery_runtime'
require 'pp'

module ActiveJquery
  def self.included(base)
    base.extend(ClassMethods)
  end
 
  class Config
    attr_reader :model
    attr_reader :model_id
 
    def initialize(model_id)
      @model_id = model_id
      @model = model_id.to_s.camelize.constantize
    end
 
    def model_name
      @model_id.to_s
    end
  end
 
  module ClassMethods
	  def active_jquery(model_id = nil)
      # converts Foo::BarController to 'bar' and FooBarsController to 'foo_bar'
      # and AddressController to 'address'
      model_id = self.to_s.split('::').last.sub(/Controller$/, '').\
 pluralize.singularize.underscore unless model_id
 
      @active_jquery_config = ActiveJquery::Config.new(model_id)
      include ActiveJquery::InstanceMethods
    end
 
    # Make the @active_jquery_config class variable easily
    # accessable from the instance methods.
    def active_jquery_config
      @active_jquery_config || self.superclass.\
 instance_variable_get('@active_jquery_config')
    end
  end
 
	module InstanceMethods
           def setup_ajs
               if !defined? @ajs 
                  @ajs = ActiveJqueryRuntime.new(self.class.active_jquery_config.model,self)
                  @content_for_layout = String.new
                  @content_for_layout << '<script src="/' + params[:controller] + '.js" type="text/javascript"></script>' + "\n"
                  @content_for_layout << @ajs.grid_html()
                  @heading = params[:controller].humanize()
                  @title = @heading
                 end
              end
          def create
              setup_ajs()
              if params[:oper] == "del"
                 self.class.active_jquery_config.model.find(params[:id]).destroy
                else
                 if params[:id] == "_empty"
                    user_params = @ajs.filter_for_create(params)
                    myrecord = self.class.active_jquery_config.model.create
                    myrecord.update_attributes(user_params)
                    myrecord.save
                   else 
                    user_params = @ajs.filter_for_update(params)
                    self.class.active_jquery_config.model.find(params[:id]).update_attributes(user_params)
                    end
                end
              render :nothing => true
              end

           def index
               setup_ajs()
               respond_to do |format|
                 format.html{ render 'activejquery/show' }
                 format.xml {
                             myxml = String.new
                             myxml << '<?xml version="1.0" encoding="UTF-8"?>' + "\n"
                             myxml << "<root>\n"
                             findargs = Hash.new
                             #Parameters: {"nd"=>"1240472994966", "_search"=>"false",
                             #            "rows"=>"10", "page"=>"1", "sidx"=>"whom",
                             #            "sord"=>"asc", "controller"=>"airstate", 
                             #            "action"=>"index", "format"=>"xml"}

                             if params[:sord]
                                sort_order = params[:sord]
                                sort_key   = params[:sidx]
                                findargs[:order] = sort_key + " " + sort_order
                                end
                             if params[:rows]
                                myrows = params[:rows].to_i
                                mypage = params[:page].to_i
                                myrecords = self.class.active_jquery_config.model.count(:all).to_i
                                totalrecords = (myrecords / myrows) + 1
                                findargs[:limit] =  myrows
                                findargs[:offset] = (mypage - 1) * findargs[:limit]
                                myxml << '<page type="integer">' + mypage.to_s + "</page>\n"
                                myxml << '<total type="integer">' + totalrecords.to_s + '</total>' + "\n"
                                myxml << '<records type="integer">' + myrecords.to_s + "</records>\n"
                                end
                            @mydata = self.class.active_jquery_config.model.find(:all,findargs)
                            myxml << @mydata.to_xml(:dasherize => false,:skip_instruct => true)
                            myxml << "</root>\n"
                            render :xml => myxml
                            }
                 format.js  { render :js => @ajs.grid_javascript(params) }
                 end
             end


           def total_records
              return self.class.active_jquery_config.model.count(:all)
              end

              #{self.class.acts_as_exportable_config.model_name.pluralize}.xml"
	  end
 
  end

