<?php

// Fill in your deviceToken, which is in the ShotVibe app's Xcode debug log:
// SVPushNotificationsManager.m:65: Registering deviceToken: fc60d67272ffef8d80f9c3adf0544417d7f497df5221384668cf28df664ff136
$deviceToken = 'fc60d67272ffef8d80f9c3adf0544417d7f497df5221384668cf28df664ff136'; 

// Put your private key's passphrase here:
$passphrase = 'pushtest';


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

// Create the payload body
$body['aps'] = array(
	'alert' => 'ShotVibe push operational!',
	'sound' => 'default',
//	'badge' => 'Increment'  // doesn't seem to work
	'badge' => 0
	);

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