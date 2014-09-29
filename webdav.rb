#
# This is an extension to Ruby's WEBrick that handles the details of WebDAV
# extensions.  The base extensions are a set of errors, a 'Resource' class
# that represents an object which is the tail of a URI,  and a 'Collection' class
# that is like a directory
#

require 'webrick'
require 'rexml/document'
include REXML

module WebDAV

    class ClientError < StandardError

	def initialize(body=nil, type='text/xml')
	    @body = body
	    @type = type
	end

	def body
	    case
	    when @body.is_a?(String) ;
		error = Element.new('error')
		error << Element.new('message').add_text(@body)
		Build.document(error).to_s
	    when @body.is_a?(Document) ; @body.to_s
	    when @body.is_a?(Element)  ; Build.document(@body).to_s
	    else @body
	    end
	end

	def prepare(response)
	    response.status = @status
	    response['content-type'] = @type
	    response.body = self.body.to_s
	end

    end

    class Accepted < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 202
	end
    end

    class BadRequest < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 400
	end
    end

    class Forbidden < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 403
	end
    end

    class NotFound < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 404
	end
    end

    class Conflict < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 409
	end
    end

    class RequestEntityTooLarge < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 413
	end
    end

    class ExpectationFailed < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 417
	end
    end

    class UnprocessableEntity < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 422
	end
    end

    class FailedDependency < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 424
	end
    end

    class InternalServerError < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 500
	end
    end

    class NotImplemented < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 501
	end
    end

    class ServiceUnavailable < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 503
	end
    end

    class InsufficientStorage < ClientError
	def initialize(body=nil, type='text/xml')
	    super
	    @status = 507
	end
    end

    module Build
	def Build.status(text)
	    text = 'HTTP/1.1 200 OK' if text.nil?
	    Element.new('status').add_text(text)
	end

	def Build.propstat(properties, response_line)
	    xml = Element.new('propstat')
	    xml << properties.to_xml
	    xml << status(response_line)
	    xml
	end

	def Build.response(uri, proplist, response_line=nil)
	    xml = Element.new('response')
	    xml << Element.new('href').add_text(uri)
	    xml << propstat(proplist, response_line)
	    xml
	end

	def Build.multistatus(element=nil)
	    xml = Element.new('multistatus')
	    xml.add_namespace("DAV:")
	    xml << element unless element.nil?
	    xml
	end

	def Build.document(element=nil)
	    return element if element.is_a?(String) # Pass through a string unmodified
	    doc = Document.new
	    decl = XMLDecl.new
	    decl.encoding = 'utf-8'
	    doc << decl
	    xsl = Instruction.new('xml-stylesheet', 'type="text/xsl" href="/style/spine.xsl"')
	    doc << xsl
	    doc << element unless element.nil?
	    doc
	end

	def Build.exception(exception)
	    xml = Element.new('exception')
	    xml << Element.new('description').add_text(exception.to_s)
	    xml << Element.new('class').add_text(exception.class.to_s)
	    stack = Element.new('stack')
	    exception.backtrace.each { |frame|
		stack << Element.new('frame').add_text(frame.to_s)
	    }
	    xml << stack
	    Build.document(xml)
	end

    end

    module Prepare
	def Prepare.ok(response, xml=nil)
	    response.status = 200
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.created(response, xml=nil)
	    response.status = 201
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.accepted(response, xml=nil)
	    response.status = 202
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.non_authoritative(response, xml=nil)
	    response.status = 203
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.no_content(response)
	    response.status = 204
	    response['content-type'] = 'text/xml'
	end
	def Prepare.reset_content(response)
	    response.status = 205
	    response['content-type'] = 'text/xml'
	end
	def Prepare.multistatus(response, xml=nil)
	    response.status = 207
	    response.reason_phrase = 'Multi-Status'
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.not_modified(response, xml=nil)
	    response.status = 304
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.temporary_redirect(response, xml=nil)
	    response.status = 307
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.bad_request(response, xml=nil)
	    response.status = 400
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.forbidden(response, xml=nil)
	    response.status = 403
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.not_found(response, xml=nil)
	    response.status = 404
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.method_not_allowed(response, xml=nil)
	    response.status = 405
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.conflict(response, xml=nil)
	    response.status = 409
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.precondition_failed(response, xml=nil)
	    response.status = 412
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.request_entity_too_large(response, xml=nil)
	    response.status = 413
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.unprocessable_entity(response, xml=nil)
	    response.status = 422
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.failed_dependency(response, xml=nil)
	    response.status = 424
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.server_error(response, exception)
	    response.status = 500
	    response['content-type'] = 'text/xml'
	    response.body = Build.exception(exception).to_s
	end
	def Prepare.not_implemented(response, xml=nil)
	    response.status = 501
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.bad_gateway(response, xml=nil)
	    response.status = 502
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.service_unavaliable(response, xml=nil)
	    response.status = 503
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end
	def Prepare.gateway_timeout(response, xml=nil)
	    response.status = 504
	    response['content-type'] = 'text/xml'
	    return if xml.nil?
	    response.body = xml.to_s
	end

    end

    class Property
	def initialize(key, value, namespace=nil)
	    @key = key
	    @value = value
	    @namespace = namespace
	end
	def to_xml
	    key = namespace.nil? ? @key : "#{namespace}:#{@key}"
	    element = Element.new(key)
	    case @value
	    when Element; element << value
	    else element.text = value.to_s
	    end
	    element
	end
    end

    class PropertyList
	def initialize(hash={})
	    @prop = Element.new('prop')
	    hash.each do |key,value|
		@prop << Element.new(key)
		self[key] = value
	    end
	end

	def [] (key) @prop.elements[key] end
	def []= (key, value)
	    element = @prop.elements[key]
	    @prop.delete_element(element) unless element.nil?
	    @prop << Element.new(key)
	    case value
	    when Element; @prop.elements[key] << value
	    else @prop.elements[key].text = value.to_s
	    end
	end

	def to_xml()
	    # xml = Element.new('prop')
	    @prop
	end
    end

    class Resource < WEBrick::HTTPServlet::AbstractServlet
	attr :filename
	# changeover to use name not filename
	def name() @filename end

	def inspect() @filename end

	def initialize(server, filename, controller=nil)
	    super(server)
	    @filename = filename
	    @controller = controller

	    @properties = PropertyList.new(
	    'creationdate'   => Time.now.httpdate,
	    'getlastmodified' => Time.now.httpdate,
	    'displayname'    => @filename,
	    'getcontenttype' => 'text/xml; charset=UTF-8',
	    'resourcetype'   => ''
	    )
	end
	def get_instance(server, *options) self end
	def parent=(collection)
	    raise "parent must be a collection" unless collection.is_a? Collection
	    @parent = collection
	end

	def path
	    return @filename if @parent.nil?
	    @parent.path + @filename
	end

	def forbidden(response)
	    response.body = ''
	    response.status = 403
	end

	def properties() @properties.to_xml end
	def to_prop() Build.response(path, @properties) end

	# Can override default implementation
	def ready?
	    if @controller and @controller.respond_to?(:ready?)
		@controller.ready?
	    else
		true
	    end
	end

	def do_MOVE(request, response)
	    if respond_to? :move
		data = move(request['destination'])
		return Prepare.ok(response) if data.nil?
		xml = Build.document(data)
		return Prepare.ok(response, xml)
	    end
	    return Prepare.not_found(response) if @controller.nil?
	    if @controller.respond_to? :move
		data = @controller.move(request['destination'])
		return Prepare.ok(response) if data.nil?
		xml = Build.document(data)
		return Prepare.ok(response, xml)
	    end
	    return Prepare.forbidden(response)
	rescue ClientError => exception
	    $log.debug('WebDAV') {"exception in Resource MOVE #{exception}"}
	    exception.prepare(response)
	end

	def do_PROPFIND(request, response)
	    xml = Build.multistatus
	    xml << Build.response(path, @properties)
	    Prepare.multistatus(response, Build.document(xml))

	end

	def do_PROPPATCH(request, response)
	    xml = Build.multistatus
	    xml << Build.response(path, @properties)
	    Prepare.multistatus(response, Build.document(xml))

	end

	def do_OPTIONS(request, response)
	    super(request, response)
	    response['DAV'] = '1'
	    # response['MS-Author-Via'] = 'DAV'
	end

	def do_COPY(request, response) forbidden(response) end
	def do_TRACE(request, response) forbidden(response) end

	def do_GET(request, response)
	    if respond_to? :redirect
		location = redirect()
		response['Location'] = location
		return Prepare.temporary_redirect(response)
	    end

	    if respond_to? :get
		return if __getCheckNotModified__(request, response, self)
		if request.to_s =~ /topology/
		   xml = "<?xml version='1.0' encoding='UTF-8'?>"
		   xml << "<?xml-stylesheet type=\"text/xsl\" href=\"/style/spine.xsl\"?>"
		   xml << get_string
		   return Prepare.ok(response, xml)
		end
		xml = Build.document(get)
		return Prepare.ok(response, xml)
	    end

	    return Prepare.not_found(response) if @controller.nil?

	    if @controller.respond_to? :get
		return if __getCheckNotModified__(request, response, @controller)
		xml = Build.document(@controller.get)
		return Prepare.ok(response, xml)
	    end

	    if @controller.respond_to? :to_xml
		# don't build doc?
		return Prepare.ok(response, @controller.to_xml)
	    end

	    return Prepare.not_found(response)
	end

	def do_POST(request, response)
	    begin
		case
		when        self.respond_to?(:post) ; data = post(request.body)
		when @controller.nil?               ; return Prepare.not_found(response)
		when @controller.respond_to?(:post) ; data = @controller.post(request.body)
		else raise Forbidden.new
		end
	    rescue ClientError => exception
		exception.prepare(response)
	    rescue Exception => exception
		logException("#{self.class}.POST",exception)
		Prepare.server_error(response, exception)
	    else
		doc = data.nil? ? nil : Build.document(data)
		Prepare.ok(response, doc)
	    end
	end

	def do_PUT(request, response)
	    begin
		method = :put
		begin
		    # only do this is the content-type is xml (spine even...)
		    doc = Document.new(request.body)
		    doc.instructions.each do |instruction|
			next unless instruction.target == 'peer'
			method = instruction.content.intern
		    end
		rescue Exception => e
		    $log.warn('Resource') {"ignoring error processing document intructions"}
		    $log.warn('Resource') {"  ==> #{e}"}
		end
		case
		when        self.respond_to?(method) ; data = self.__send__(method, request.body)
		when @controller.nil?                ; return Prepare.not_found(response)
		when @controller.respond_to?(method) ; data = @controller.__send__(method, request.body)
		else raise Forbidden.new
		end
	    rescue NoMethodError => e
		$log.debug('WebDAV') {"exception in Resource PUT"}
		$log.debug {" ==> #{e} <=="}
		e.backtrace.each { |line| $log.debug {" => #{line}"} }
		Prepare.method_not_allowed(response)
	    rescue NameError => e
		$log.debug('WebDAV') {"exception in Resource PUT #{e}"}
		Prepare.bad_request(response)
	    rescue RangeError => e
		$log.debug('WebDAV') {"exception in Resource PUT #{e}"}
		Prepare.request_entity_too_large(response)
	    rescue ArgumentError => e
		$log.debug('WebDAV') {"exception in Resource PUT #{e}"}
		Prepare.bad_request(response)
	    rescue ClientError => e
		$log.debug('WebDAV') {"exception in Resource PUT #{e}"}
		e.prepare(response)
	    rescue Exception => exception
		logException("#{self.class}.PUT", exception)
		Prepare.server_error(response, exception)
	    else
		doc = data.nil? ? nil : Build.document(data)
		return Prepare.created(response, doc)
	    end
	end

	def do_DELETE(request, response)
	    begin
		case
		when        self.respond_to?(:delete) ; data = delete(request.body)
		when @controller.nil?                 ; return Prepare.not_found(response)
		when @controller.respond_to?(:delete) ; data = @controller.delete(request.body)
		else raise Forbidden.new
		end
	    rescue ClientError => exception
		exception.prepare(response)
	    else
		doc = data.nil? ? nil : Build.document(data)
		return Prepare.ok(response, doc)
	    end
	end

	def __getCheckNotModified__(request, response, controller)
	    return false unless controller.respond_to? :lastModified
	    lastModified = controller.lastModified
	    return false if lastModified.nil?
	    response['Last-Modified'] = lastModified.httpdate
	    return false if request['If-Modified-Since'].nil?
	    ifModifiedSince = Time.httpdate(request['If-Modified-Since'])
	    return false if lastModified > ifModifiedSince
	    Prepare.not_modified(response)
	    return true
	end

    end

    class Collection < Resource
	def initialize(server, filename, controller=nil)
	    super(server, filename, controller)
	    @properties['resourcetype'] = Element.new('collection')
	    @properties['displayname'] = @filename
	    @children = []
	    @views = Hash.new
	end

	def children()
	    @children + @views.values
	end
	def add(resource)
	    return if @children.include?(resource)
	    @children << resource
	    resource.parent = self
	    logDebug {"mounting #{resource.path} as #{resource}"}
	    @server.mount(resource.path, resource)
	end
	def remove(resource)
	    @server.unmount(resource.path)
	    @children.delete(resource)
	end
	# return resource for reuse
	def register(resource_type, filename, object)
	    resource = resource_type.new(@server, filename, object)
	    add(resource)
	    resource
	end
	def add_instance(resource)
	    resource.parent = self
	    @views[resource.name] = resource
	    resource
	end
	def add_view(type, name, controller)
	    resource = type.new(@server, name, controller)
	    resource.parent = self
	    @views[name] = resource
	    resource
	end
	def add_resource(name, controller)
	    add_view(Resource, name, controller)
	end
	def add_collection(name, controller)
	    add_view(Collection, name, controller)
	end
	def add_dictionary(name, controller)
	    add_view(Dictionary, name, controller)
	end

	def path
	    return '/' if @parent.nil?
	    @parent.path + @filename + '/'
	end

	def do_GET(request, response)
	    segments = request.path.sub(path, '').split('/')
	    return super(request, response) if segments.size == 0
	    lookup = segments.shift
	    handler = @views[lookup]
	    if handler.nil?
		handler = children.detect { |child| child.name == lookup }
		return Prepare.not_found(response) if handler.nil?
	    end
	    return Prepare.method_not_allowed(response) unless handler.respond_to? :do_GET
	    begin
		handler.do_GET(request, response)
	    rescue ClientError => exception
		exception.prepare(response)
	    rescue Exception => exception
		logException("#{self.class}.GET", exception)
		Prepare.server_error(response, exception)
	    end
	end

	def do_POST(request, response)
	    segments = request.path.sub(path, '').split('/')
	    return super(request, response) if segments.size == 0
	    lookup = segments.shift
	    handler = @views[lookup]
	    if handler.nil?
		handler = children.detect { |child| child.name == lookup }
		return Prepare.not_found(response) if handler.nil?
	    end
	    return Prepare.method_not_allowed(response) unless handler.respond_to? :do_POST
	    begin
		handler.do_POST(request, response)
	    rescue ClientError => exception
		exception.prepare(response)
	    rescue Exception => exception
		logException("#{self.class}.POST", exception)
		Prepare.server_error(response, exception)
	    end
	end

	def do_PUT(request, response)
	    segments = request.path.sub(path, '').split('/')
	    return super(request, response) if segments.size == 0
	    lookup = segments.shift
	    handler = @views[lookup]
	    if handler.nil?
		handler = children.detect { |child| child.name == lookup }
	    end
	    if handler.nil?
		logDebug {"put to '#{lookup}' as xml doc"}
		# return Prepare.not_found(response) unless /xml/.match(request['content-type'])
		begin
		    doc = Document.new(request.body)
		    doc.root << Element.new('name').add_text(lookup)
		    body = doc.to_s
		    case
		    when        self.respond_to?(:put) ; data = put(body)
		    when @controller.nil?              ; return Prepare.not_found(response)
		    when @controller.respond_to?(:put) ; data = @controller.put(body)
		    else raise Forbidden.new
		    end
		rescue ClientError => exception
		    exception.prepare(response)
		rescue NoMethodError => e
		    return Prepare.method_not_allowed(response)
		rescue ArgumentError => e
		    return Prepare.bad_request(response)
		rescue Exception => e
		    logDebug {"update failed <#{e}>"}
		    return Prepare.not_found(response)
		else
		    doc = data.nil? ? nil : Build.document(data)
		    return Prepare.created(response, doc)
		end
	    end
	    return Prepare.method_not_allowed(response) unless handler.respond_to? :do_PUT
	    handler.do_PUT(request, response)
	end

	def do_DELETE(request, response)
	    segments = request.path.sub(path, '').split('/')
	    return super(request, response) if segments.size == 0
	    lookup = segments.shift
	    handler = @views[lookup]
	    if handler.nil?
		handler = children.detect { |child| child.name == lookup }
		return Prepare.not_found(response) if handler.nil?
	    end
	    return Prepare.method_not_allowed(response) unless handler.respond_to? :do_DELETE
	    begin
		handler.do_DELETE(request, response)
	    rescue ClientError => exception
		exception.prepare(response)
	    rescue Exception => exception
		logException("#{self.class}.DELETE", exception)
		Prepare.server_error(response, exception)
	    end
	end

	def do_MOVE(request, response)
	    segments = request.path.sub(path, '').split('/')
	    if segments.size == 0
		return super(request, response)
	    end
	    lookup = segments.shift
	    handler = @views[lookup]
	    if handler.nil?
		handler = children.detect { |child| child.name == lookup }
		return Prepare.not_found(response) if handler.nil?
	    end
	    return Prepare.method_not_allowed(response) unless handler.respond_to? :do_MOVE

	    begin
		handler.do_MOVE(request, response)
	    rescue ClientError => exception
		exception.prepare(response)
	    rescue Exception => exception
		logException("#{self.class}.MOVE", exception)
		Prepare.server_error(response, exception)
	    end
	end

	def propfind(request)
	    xml = Build.multistatus
	    xml << Build.response(path, @properties)
	    if request['depth'].to_i != 0
		children.each { |child| xml << child.to_prop }
	    end
	    Build.document(xml)
	end

	def do_PROPFIND(request, response)
	    segments = request.path.sub(path, '').split('/')
	    if segments.size == 0
		return Prepare.multistatus(response, propfind(request))
	    end

	    lookup = segments.shift
	    handler = @views[lookup]
	    if handler.nil?
		handler = children.detect { |child| child.name == lookup }
		return Prepare.not_found(response) if handler.nil?
	    end

	    return Prepare.method_not_allowed(response) unless handler.respond_to? :do_PROPFIND
	    handler.do_PROPFIND(request, response)
	end

	def do_PROPPATCH(request, response)
	    xml = Build.multistatus
	    xml << Build.response(path, @properties)
	    response.body = Build.document(xml).to_s
	    response.status = 207
	    response.reason_phrase = 'MultiStatus'
	    response['content-type'] = 'text/xml'
	    xml
	end

	def do_MKCOL(request, response) forbidden(response) end

    end

end

# vim:expandtab
# vim:autoindent
