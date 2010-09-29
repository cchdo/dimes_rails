module PagesHelper
    def captioned_image(imgsrc, cap, opts)
        content_tag(:p, image_tag(imgsrc,
                                  {:alt => cap, :title => cap}.merge(opts))) + content_tag(:p, cap, :class => :cap)
    end
end
