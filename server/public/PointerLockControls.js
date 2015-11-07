/**
 * @author mrdoob / http://mrdoob.com/
 */

THREE.PointerLockControls = function ( camera ) {

	var scope = this;

	camera.up.set(0, 0, 1);
	camera.lookAt(new THREE.Vector3( 0, 1, 0 ));
	//camera.rotation.set( 0, 0, 0 );

	var pitchObject = new THREE.Object3D();
	pitchObject.add( camera );

	var yawObject = new THREE.Object3D();
	yawObject.position.z = 10;
	yawObject.add( pitchObject );
	
	var PI_2 = Math.PI / 2;

	var onMouseMove = function ( event ) {

		if ( scope.enabled === false ) return;

		var movementX = event.movementX || event.mozMovementX || 0;
		var movementY = event.movementY || event.mozMovementY || 0;

		yawObject.rotation.z -= movementX * 0.002;
		pitchObject.rotation.x -= movementY * 0.002;

		pitchObject.rotation.x = Math.max( - PI_2, Math.min( PI_2, pitchObject.rotation.x ) );

	};

	this.dispose = function() {

		document.removeEventListener( 'mousemove', onMouseMove, false );

	}

	document.addEventListener( 'mousemove', onMouseMove, false );

	this.enabled = false;

	this.getRotation = function() {
		return [yawObject.rotation.z, yawObject.rotation.x];
	}

	this.getObject = function () {

		return yawObject;

	};
};