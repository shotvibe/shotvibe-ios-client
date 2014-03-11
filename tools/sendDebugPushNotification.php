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
    $body = array(
              'aps' => array(
                         'alert' => "Someone invited you to join album ${argv[2]}",
                         'sound' => 'default',
                       ),
              'album_id' => $argv[3]
            );
    break;
  case 'add':
    $body = array(
              'aps' => array(
                         'alert' => "Someone added ${argv[2]} photos to album ${argv[3]}",
                         'sound' => 'default',
                       ),
              'album_id' => $argv[3]
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

echo "Sending $command push notification to device with token: $deviceToken\nand pass phrase: \"$passphrase\"\n";

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
