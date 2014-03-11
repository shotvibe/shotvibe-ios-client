<?php

/* Make sure there is a ./deviceToken.txt file that contains a single line with the target device's token,
   which is in the ShotVibe app's Xcode debug log:

 SVPushNotificationsManager.m:65: Registering deviceToken: fc60d67272ffef8d80f9c3adf0544417d7f497df5221384668cf28df664ff136

*/

$command = $argv[1];

$fh = fopen("deviceToken.txt", 'r');
$deviceToken = fgets($fh);
fclose($fh);

$passphrase = "pushtest";



// Create the payload body
switch ($command) {
  case 'invite':
    $name = $argv[3] ?: 'Someone';
    $albumName = $argv[4] ?: 'Holiday 2014';
    $body = array(
              'aps' => array(
                         'alert' => "$name added you to the album $albumName",
                         'sound' => 'default'
                       ),
              'type' => 'added_to_album',
              'album_id' => intval($argv[2]),
              'adder' => $name,
              'album_name' => $albumName
            );
    break;
  case 'add':
    $nrOfPhotos = intval($argv[3]) ?: 17;
    $name = $argv[4] ?: 'Someone';
    $albumName = $argv[5] ?: 'Holiday 2014';
    $body = array(
              'aps' => array(
                         'alert' => "$name added $nrOfPhotos photos to the album $albumName",
                         'sound' => 'default'
                       ),
              'type' => 'photos_added',
              'album_id' =>intval($argv[2]),
              'num_photos' => $nrOfPhotos,
              'author' => $name,
              'album_name' => $albumName
            );
    break;
  case 'sync':
    $body = array(
              'aps' => array(
                       ),
              'type' => 'album_list_sync'
            );
    break;
  case 'albumsync':
    $body = array(
              'aps' => array(
                       ),
              'type' => 'album_sync',
              'album_id' => intval($argv[2])       
            );
    break;
  case 'test':
    $body = array(
              'aps' => array(
                         'alert' => "Test Message: ${argv[2]}",
                         'sound' => 'default'
                       ),
              'type' => 'test_message',
              'message' => $argv[2]
            );
    break;
  case 'badge':
    $body = array(
              'aps' => array(
                      	 'alert' => "Setting notification badge to ${argv[2]}",
                      	 'sound' => 'default',
                      	 'badge' => intval($argv[2])
                    	 ),
    );
    break;
  case 'reset':
    $body = array(
              'aps' => array(
                       	 'badge' => 0
                    	 ),
    );
    break;
 
  default:
    echo "Unknown command: $command\n";
  exit;
}

echo "Sending $command push notification to device with token:\n$deviceToken\nand pass phrase: \"$passphrase\"\n";
print_r ($body);

////////////////////////////////////////////////////////////////////////////////

$ctx = stream_context_create();
stream_context_set_option($ctx, 'ssl', 'local_cert', 'ck.pem');
stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

// Open a connection to the APNS server
$fp = stream_socket_client(
	'ssl://gateway.sandbox.push.apple.com:2195', $err,
	$errstr, 60, STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, $ctx);

if (!$fp)
	exit("Failed to connect: $err $errstr" . PHP_EOL);

echo 'Connected to APNS' . PHP_EOL;

// Encode the payload as JSON
$payload = json_encode($body);

// Build the binary notification
$msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;

// Send it to the server
$result = fwrite($fp, $msg, strlen($msg));

if (!$result)
	echo 'Message not delivered' . PHP_EOL;
else
	echo 'Message successfully delivered' . PHP_EOL;

// Close the connection to the server
fclose($fp);
