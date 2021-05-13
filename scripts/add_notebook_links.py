# Import OMERO Python BlitzGateway
from getpass import getpass
import omero.gateway
from omero.gateway import BlitzGateway


# Step 1
def connect(hostname, username, password):
    """
    Connect to an OMERO server
    :param hostname: Host name
    :param username: User
    :param password: Password
    :return: Connected BlitzGateway
    """
    conn = BlitzGateway(username, password,
                        host=hostname, secure=True)
    conn.connect()
    conn.c.enableKeepAlive(60)
    return conn


# Step 2
def add_annotation(conn, pattern, delete_annotation):
    """
    Load the plates in the specified screen
    :param conn: The BlitzGateway
    :param pattern: The string the name of the screen starts with.
    :param delete_annotation: Pass True to delete the annotation,
                              False otherwise
    """
    notebook_name = "idr0094-ic50.ipynb"
    ref_url = "https://binder.bioimagearchive.org/v2/gh/IDR/idr0094-ellinger-sarscov2/master?urlpath=notebooks%2Fnotebooks%2Fidr0094-ic50.ipynb%3FscreenId%3D"  # noqa
    namespace = "openmicroscopy.org/idr/analysis/notebook"
    for screen in conn.listScreens():
        name = screen.getName()
        n = len(list(screen.listChildren()))
        if name.startswith(pattern) and n > 0:
            if delete_annotation:
                to_delete = []
                for ann in screen.listAnnotations(ns=namespace):
                    to_delete.append(ann.id)
                if to_delete:
                    conn.deleteObjects('Annotation', to_delete, wait=True)
            url = ref_url + str(screen.getId())
            key_value_data = [["Study Notebook", notebook_name],
                              ["Study Notebook URL", url]]
            map_ann = omero.gateway.MapAnnotationWrapper(conn)
            map_ann.setValue(key_value_data)
            map_ann.setNs(namespace)
            map_ann.save()
            screen.linkAnnotation(map_ann)


# main
if __name__ == "__main__":
    try:
        # Collect parameters
        host = input("Host [localhost]: ") or 'localhost'  # noqa
        username = input("Username [demo]: ") or 'demo'
        password = getpass("Password: ")
        pattern = input("Pattern [idr0094]: ") or 'idr0094'
        delete_annotation = input("Delete annotation [False]: ") or 'False'

        # Connect to the server
        conn = connect(host, username, password)

        # Annotate the screens with plates starting with the pattern
        add_annotation(conn, pattern, delete_annotation)
    finally:
        conn.close()
    print("done")
