
# diaspora* federation lib

[![Build Status](https://travis-ci.org/Raven24/diaspora-federation.png)](https://travis-ci.org/Raven24/diaspora-federation)
[![Coverage Status](https://coveralls.io/repos/Raven24/diaspora-federation/badge.png)](https://coveralls.io/r/Raven24/diaspora-federation)

[Project site](https://diasporafoundation.org) |
[Wiki](https://wiki.diasporafoundation.org) |
[Docs](http://rdoc.info/github/Raven24/diaspora-federation/master/frames)

The goal of this gem is to provide a library of reusable code for the purpose
of implementing the protocols used around Diaspora. This covers user discovery
utilizing the [XRD](http://docs.oasis-open.org/xri/xrd/v1.0/xrd-1.0.html),
[HostMeta](http://tools.ietf.org/html/rfc6415),
[WebFinger](http://tools.ietf.org/html/draft-jones-appsawg-webfinger) and
[hCard](http://microformats.org/wiki/hCard "hCard 1.0") standards as well as
the message passing implementation using a subset of the
[Salmon protocol](http://www.salmon-protocol.org/).

One of the main ideas behind this lib was to avoid any dependencies toward a
specific web framework. This means any app using this gem is free to set up
HTTP routing and database infrastructure any way it sees fit, as long as the
few required routes are handled to specification.


### user discovery

When Diaspora attempts to discover a remote user account, the server name is
extracted from the account handle: `"user@server.example" => "server.example"`
Next, a `GET` request is sent to the servers host-meta route
`https://server.example/.well-known/host-meta` which returns an XRD document with
the `application/xrd+xml` media type.
The contained `Link` element with `rel="lrdd"` inside the
{DiasporaFederation::WebFinger::HostMeta HostMeta} document contains a template
URL in its `template` attribute. It will be used for querying the WebFinger document.

**Example:** HostMeta request

    GET /.well-known/host-meta HTTP/1.1

**Example:** HostMeta response

    HTTP/1.1 200 OK
    Content-Type: application/xrd+xml

    <?xml version="1.0" encoding="UTF-8"?>
    <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
      <Link rel="lrdd" type="application/xrd+xml" template="https://server.example/webfinger?q={uri}"/>
    </XRD>

To retrieve the {DiasporaFederation::WebFinger::WebFinger WebFinger} document,
the placeholder `{uri}` in the template has to be replaced by the `acct` URI of
the account to look up:
`https://server.example/webfinger?q=acct:user@server.example`
Now this URL can be used in a `GET` request to fetch the WebFinger document, which
also consists of an XRD document served with the `application/xrd+xml` media type.
The document already contains some basic information associated with the queried
user account. More specific profile details are in the referenced hCard document.
The URL is contained in the `href` attribute of the `Link` element with
`rel="http://microformats.org/profile/hcard"`

**Example:** WebFinger request

    GET /webfinger?q=acct:user@server.example HTTP/1.1

**Example:** WebFinger response

    HTTP/1.1 200 OK
    Content-Type: application/xrd+xml

    <?xml version="1.0" encoding="UTF-8"?>
    <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
      <Subject>acct:user@server.example</Subject>
      <Alias>https://server.example/people/0123456789abcdef</Alias>
      <Link rel="http://microformats.org/profile/hcard" type="text/html" href="https://server.example/hcard/users/user"/>
      <Link rel="http://joindiaspora.com/seed_location" type="text/html" href="https://server.example/"/>
      <Link rel="http://joindiaspora.com/guid" type="text/html" href="0123456789abcdef"/>
      <Link rel="http://webfinger.net/rel/profile-page" type="text/html" href="https://server.example/u/user"/>
      <Link rel="http://schemas.google.com/g/2010#updates-from" type="application/atom+xml" href="https://server.example/public/user.atom"/>
      <Link rel="diaspora-public-key" type="RSA" href="ABCDEF=="/>
    </XRD>

The {DiasporaFederation::WebFinger::HCard hCard} document can be accessed by
issuing a `GET` request to the hCard URL extracted from the WebFinger document.
It will return a simple HTML page with the `text/html` media type, containing the
public profile information of the queried user, marked up as specified in the
hCard microformat standard (using `class` attributes on the elements,
thereby giving them semantic meaning).

**Example:** hCard request

    GET /hcard/users/user HTTP/1.1

**Example:** hCard response

    HTTP/1.1 200 OK
    Content-Type: text/html

    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    [...]
    </html>

All of the described documents can be generated and parsed by classes shipped
with this gem. You can find them in the {DiasporaFederation::WebFinger} module.
See the included documentation for specifics on how to use them.


### message passing

(TODO)
