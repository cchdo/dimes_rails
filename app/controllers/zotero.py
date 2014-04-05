from pyzotero import zotero
import json


def _zotero_creator_to_string(creator):
    return ', '.join([
        creator.get('lastName', None), creator.get('firstName', None)])


def _zotero_creators_to_string(creators):
    return '; '.join([_zotero_creator_to_string(ccc) for ccc in creators])


def _convert_zotero_item_to_dict(item):
    return {
        'label': item['title'],
        'year': item['date'],
        'authors': _zotero_creators_to_string(item['creators']),
        'uri': item['url'],
#        'publisher': item['publicationTitle'],
    }


def zotero_to_json():
    zot = zotero.Zotero('247257', 'group', '0oZID54aNyXr8gvQTDZoS9Vs')

    items = zot.top(limit=35)
    itemlist = [_convert_zotero_item_to_dict(xxx) for xxx in items]

    exhibit_json = {
        'types': {
            "Document": {
                'pluralLabel':  "Documents",
            },
        },
        'properties': {
            #'year' : {
            #    'valueType':    "number"
            #},
            #'authors' : {
            #    'valueType':    "string"
            #},
            #'publisher' : {
            #    'valueType':    "string"
            #},
        },
        'items': itemlist,
    }
    return json.dumps(exhibit_json)
   

if __name__ == '__main__':
    print zotero_to_json()
