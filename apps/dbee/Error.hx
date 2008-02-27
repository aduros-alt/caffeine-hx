/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author: Danny Wilson - deCube.net
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */
package dbee;

/** General dbee.Errors which can by thrown by any dbee.* class **/
enum Error
{
	ModelDefinition( details:String );
	FieldDefinition( details:String );
	/** Thrown when trying to save an object with datafields that have invalid data. **/
	InvalidObjectData( modelClass:Class<PersistentObject>, object:PersistentObject );
	/** Thrown when a tableID was needed, but none was specified. For example in Reference, when trying to get the referred object. Or in Model, when trying to save the object. **/
	NoTableID( object:Dynamic );
	/** Thrown when an Object ID (usually _oid) was needed but not found. **/
	NoObjectID( object:PersistentObject );
}

#if neko
/** Things that can go wrong while trying to deserialize a PersistentObject **/
enum DeSerializerError {
	/** Thrown when trying to deserialize an object which class version number is higher then the classversion compiled in the application **/
	CannotDowngrade( lowVersion:Int, highVersion:Int, tableID:String );
}

/** Possible errors a Transaction-log reader can encounter. **/
enum TransactionLogReaderError {
	/** Thrown when something is wrong with the managerMap configuration **/
	ManagerMapConfiguration;
}

/** Possible errors a data (Transaction-)log writer can encounter. **/
enum LoggerError {
	/** Thrown when trying to log something, but no writer is configured **/
	NoWriterConfigured( loggingClassName:String );
}

/** Possible errors a PersistenceManager can encounter. **/
enum PersistenceManagerError {
	/** Thrown when the given PersistentObject class has a negative or null version number **/
	UnversionedClass( className:String );
	/** Thrown when the Manager didn't get a get modelID supplied to identify the given class. **/
	NoTableIDGiven( className:String );
	/** Thrown when the manager was trying to map itself in dbee.Configuration.persistenceManager.tableMapping which allready had a manager set. **/
	TableIDTaken( TableIDTaken:String );
}

enum ReferenceError {
	/** Thrown when setting a record to a dbee.Reference where the record manager has a different TableID then the reference. **/
	WrongTableID( RefTableID:String, ObjTableID:String, ref:Dynamic );
}
#end
