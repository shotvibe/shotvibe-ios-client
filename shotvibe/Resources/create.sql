-------------------------------------------------------------------------------
-- The photo albums that are available to the app
-------------------------------------------------------------------------------

CREATE TABLE album(
-- The album_id is the value that is returned from the server
album_id INTEGER PRIMARY KEY,

-- The user friendly name of the album, also returned from the server
name TEXT NOT NULL,

creator_id INTEGER REFERENCES username NOT NULL,

date_created DATETIME NOT NULL,

last_updated DATETIME NOT NULL,

-- The value from the HTTP ETag header for the album 
last_etag TEXT,

num_new_photos INTEGER,

last_access DATETIME NULL
);

CREATE TABLE user(
-- The id is the value that is returned from the server
user_id INTEGER PRIMARY KEY,

-- The user friendly name of the user, returned from the server
nickname TEXT NOT NULL,

-- The URL of the avatar image of the user, returned from the server
avatar_url TEXT NOT NULL
);

CREATE TABLE photo(
-- The album that this photo belongs to
photo_album INTEGER REFERENCES album,

-- The order of the photos in the album is according to this field
num INTEGER NOT NULL,

-- The name of the image file (without a ".jpg" extension), as returned from the server
photo_id TEXT NOT NULL,

-- The original photo URL
url TEXT NOT NULL,

-- The user who uploaded this photo
author_id INTEGER REFERENCES username,

-- The timestamp this photo was uploaded, also returned from the server
created DATETIME NOT NULL,

UNIQUE(photo_album, photo_id)
);

CREATE TABLE photo_glance(
-- The photo that this glances
photo_id TEXT REFERENCES photo(photo_id),

-- The user who created this glance
author_id INTEGER REFERENCES username,

-- The name of the emoticon that the author chose
emoticon_name TEXT NOT NULL,

-- The order of the glances as returned by the server
num INTEGER NOT NULL,

UNIQUE(author_id, photo_id)
);

CREATE TABLE album_member(
-- The user
user_id INTEGER REFERENCES user,

-- The album that this user is a member of
album_id INTEGER REFERENCES album,

UNIQUE(user_id, album_id)
);

CREATE TABLE uploading_photo(
-- The album that this photo is being uploaded to
album_id INTEGER REFERENCES album,

-- The location of the temporary file on the device filesystem
tmp_filename TEXT NOT NULL,

-- If a value is set for photo_id it means that the photo has already been uploaded, and just needs to be added to the album
photo_id TEXT
);

CREATE TABLE phone_contact(
-- A phone number as it appears in the device phone book
phone_number TEXT NOT NULL,

-- Contact name
last_name TEXT NOT NULL,
first_name TEXT NOT NULL,

-- Is this a mobile phone number or not
is_mobile BOOLEAN NOT NULL,

-- The user of this phone number, or NULL if the number does not belong to a registered user
user_id INTEGER,

-- Avatar url for registered and unregistered users
avatar_url TEXT,

-- Phone number in canonical form, or NULL if the number is invalid
canonical_number TEXT,

-- When this phone number was last queried
query_time DATETIME NOT NULL,

UNIQUE(phone_number, last_name, first_name)
);

-- Efficiently delete an uploading_photo by photo_id
CREATE INDEX uploading_photo_index ON uploading_photo(photo_id);

-- These indexes are necessary in order to efficiently retrieve all of the
-- photos of a particular album, or all of the members of a particular album

CREATE INDEX photo_index ON photo(photo_album);
CREATE INDEX album_member_index ON album_member(album_id);

-- This index is necessary in order to efficiently retrieve photos sorted by
-- correct order, and also to efficiently retrieve the latest n photos

CREATE INDEX photo_num_index ON photo(num);
