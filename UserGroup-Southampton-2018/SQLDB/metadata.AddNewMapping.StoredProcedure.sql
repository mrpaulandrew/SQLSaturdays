USE [sdbamsdapdev001]
GO
/****** Object:  StoredProcedure [metadata].[AddNewMapping]    Script Date: 06/06/2018 14:51:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [metadata].[AddNewMapping]
	(
	@DataFlowName VARCHAR(255),
	@SourceSystem VARCHAR(255),
	@TargetSystem VARCHAR(255),
	@SourceObjectPrefix VARCHAR(128),
	@SourceObject VARCHAR(128),
	@TargetObjectPrefix VARCHAR(128),
	@TargetObject VARCHAR(128),
	@SourceAttribute VARCHAR(128),
	@SourceDataType VARCHAR(128),
	@TargetAttribute VARCHAR(128),
	@TargetDataType VARCHAR(128),
	@Override BIT = 1
	)
AS

SET NOCOUNT ON;

BEGIN

	DECLARE @NewDataFlow INT
	DECLARE @NewSourceSystem INT
	DECLARE @NewTargetSystem INT
	DECLARE @NewSourceObject INT
	DECLARE @NewTargetObject INT
	DECLARE @NewSourceAttribute INT
	DECLARE @NewTargetAttribute INT
	DECLARE @NewMapping INT

	--defensive checks
	IF EXISTS
		(
		SELECT
			*
		FROM
			[metadata].[CompleteMappings]
		WHERE
			[DataFlowName] = @DataFlowName
			AND [SourceSystem] = @SourceSystem
			AND [TargetSystem] = @TargetSystem
			AND [SourceObjectPrefix] = @SourceObjectPrefix
			AND [SourceObject] = @SourceObject
			AND [TargetObjectPrefix] = @TargetObjectPrefix
			AND [TargetObject] = @TargetObject
			AND [SourceAttribute] = @SourceAttribute
			AND [SourceDataType] = @SourceDataType
			AND [TargetAttribute] = @TargetAttribute
			AND [TargetDataType] = @TargetDataType
		)
		BEGIN
			RAISERROR('This exact mapping already exists. Returning.',16,1)
			RETURN;
		END

	---------------------------------------------------------------------------------------------
	--									data flow
	---------------------------------------------------------------------------------------------
	IF NOT EXISTS
		(
		SELECT * FROM [metadata].[DataFlows] WHERE [DataFlowName] = @DataFlowName
		)
		BEGIN
			IF @Override = 1
				BEGIN
					PRINT 'Creating data flow.'

					INSERT INTO [metadata].[DataFlows]
						(
						[DataFlowName],
						[InUse]
						)
					VALUES
						(
						@DataFlowName,
						1
						)

					SET @NewDataFlow = SCOPE_IDENTITY()
				END
			ELSE
				BEGIN
					RAISERROR('Data flow name does not exist.',16,1);
					RETURN;
				END
		END
		ELSE
		BEGIN
			PRINT 'Found data flow.'
			
			SELECT
				@NewDataFlow = [DataFlowId]
			FROM
				[metadata].[DataFlows]
			WHERE
				[DataFlowName] = @DataFlowName
		END

	
	---------------------------------------------------------------------------------------------
	--									source system
	---------------------------------------------------------------------------------------------
	IF NOT EXISTS
		(
		SELECT * FROM [metadata].[Systems] WHERE [SystemName] = @SourceSystem
		)
		BEGIN
			IF @Override = 1
				BEGIN
					PRINT 'Creating source system.'
					
					INSERT INTO [metadata].[Systems]
						(
						[SystemName],
						[SystemTechnologyId],
						[CreatedDate]
						)
					SELECT
						@SourceSystem,
						[SystemTechId],
						GETDATE()
					FROM
						[metadata].[SystemTechnologies]
					WHERE
						[TechnologyName] = 'Unknown'

					SET @NewSourceSystem = SCOPE_IDENTITY()
				END
			ELSE
				BEGIN		
					RAISERROR('Source system does not exist.',16,1);
					RETURN;
				END
		END
		ELSE
		BEGIN
			PRINT 'Found source system.'
			
			SELECT
				@NewSourceSystem = [SystemId]
			FROM
				[metadata].[Systems]
			WHERE
				[SystemName] = @SourceSystem
		END


	---------------------------------------------------------------------------------------------
	--									target system
	---------------------------------------------------------------------------------------------
	IF NOT EXISTS
		(
		SELECT * FROM [metadata].[Systems] WHERE [SystemName] = @TargetSystem
		)
		BEGIN
			IF @Override = 1
				BEGIN
					PRINT 'Creating target system.'

					INSERT INTO [metadata].[Systems]
						(
						[SystemName],
						[SystemTechnologyId],
						[CreatedDate]
						)
					SELECT
						@TargetSystem,
						[SystemTechId],
						GETDATE()
					FROM
						[metadata].[SystemTechnologies]
					WHERE
						[TechnologyName] = 'Unknown'
				
					SET @NewTargetSystem = SCOPE_IDENTITY()
				END
			ELSE
				BEGIN		
					RAISERROR('Target system does not exist.',16,1);
					RETURN;
				END
		END
		ELSE
		BEGIN
			PRINT 'Found target system.'
			
			SELECT
				@NewTargetSystem = [SystemId]
			FROM
				[metadata].[Systems]
			WHERE
				[SystemName] = @TargetSystem
		END


	---------------------------------------------------------------------------------------------
	--									source object
	---------------------------------------------------------------------------------------------
	IF NOT EXISTS
		(
		SELECT * FROM [metadata].[Objects] WHERE [ObjectName] = @SourceObject AND [ObjectPrefix] = @SourceObjectPrefix AND [SystemId] = @NewSourceSystem
		)
		BEGIN
			IF @Override = 1
				BEGIN
					PRINT 'Creating source object.'
					
					INSERT INTO [metadata].[Objects]
						(
						[ObjectTypeId],
						[ObjectPrefix],
						[ObjectName],
						[SystemId]
						)
					SELECT
						[ObjectTypeId],
						@SourceObjectPrefix,
						@SourceObject,
						@NewSourceSystem
					FROM
						[metadata].[ObjectTypes]
					WHERE
						[ObjectTypeName] = 'Unknown'

					SET @NewSourceObject = SCOPE_IDENTITY()
				END
			ELSE
				BEGIN
					RAISERROR('Source object does not exist.',16,1);
					RETURN;
				END
		END
		ELSE
		BEGIN
			PRINT 'Found source object.'
			
			SELECT
				@NewSourceObject = [ObjectId]
			FROM
				[metadata].[Objects]
			WHERE
				[ObjectName] = @SourceObject
				AND [ObjectPrefix] = @SourceObjectPrefix 
				AND [SystemId] = @NewSourceSystem
		END


	---------------------------------------------------------------------------------------------
	--									target object
	---------------------------------------------------------------------------------------------
	IF NOT EXISTS
		(
		SELECT * FROM [metadata].[Objects] WHERE [ObjectName] = @TargetObject AND [ObjectPrefix] = @TargetObjectPrefix AND [SystemId] = @NewTargetSystem
		)
		BEGIN
			IF @Override = 1
				BEGIN
					PRINT 'Creating target object.'
					
					INSERT INTO [metadata].[Objects]
						(
						[ObjectTypeId],
						[ObjectPrefix],
						[ObjectName],
						[SystemId]
						)
					SELECT
						[ObjectTypeId],
						@TargetObjectPrefix,
						@TargetObject,
						@NewTargetSystem
					FROM
						[metadata].[ObjectTypes]
					WHERE
						[ObjectTypeName] = 'Unknown'

					SET @NewTargetObject = SCOPE_IDENTITY()
				END
			ELSE
				BEGIN
					RAISERROR('Target object does not exist.',16,1);
					RETURN;
				END
		END
		ELSE
		BEGIN
			PRINT 'Found target object.'
			
			SELECT
				@NewTargetObject = [ObjectId]
			FROM
				[metadata].[Objects]
			WHERE
				[ObjectName] = @TargetObject
				AND [ObjectPrefix] = @TargetObjectPrefix 
				AND [SystemId] = @NewTargetSystem
		END


	---------------------------------------------------------------------------------------------
	--									source attribute
	---------------------------------------------------------------------------------------------
	IF NOT EXISTS
		(
		SELECT * FROM [metadata].[Attributes] WHERE [AttributeName] = @SourceAttribute AND [ObjectId] = @NewSourceObject
		)
		BEGIN
			IF @Override = 1
				BEGIN
					PRINT 'Creating source attribute.'
					
					INSERT INTO [metadata].[Attributes]
						(
						[AttributeName],
						[DataType],
						[ObjectId]
						)
					VALUES
						( 
						@SourceAttribute,
						@SourceDataType,
						@NewSourceObject
						)

					SET @NewSourceAttribute = SCOPE_IDENTITY()
				END
			ELSE
				BEGIN
					RAISERROR('Source attribute does not exist.',16,1);
					RETURN;
				END
		END
		ELSE
		BEGIN
			PRINT 'Found source attribute.'
			
			SELECT
				@NewSourceAttribute = [AttributeId]
			FROM
				[metadata].[Attributes]
			WHERE
				[AttributeName] = @SourceAttribute
				AND [ObjectId] = @NewSourceObject
		END

	---------------------------------------------------------------------------------------------
	--									target attribute
	---------------------------------------------------------------------------------------------
	IF NOT EXISTS
		(
		SELECT * FROM [metadata].[Attributes] WHERE [AttributeName] = @TargetAttribute AND [ObjectId] = @NewTargetObject
		)
		BEGIN
			IF @Override = 1
				BEGIN
					PRINT 'Creating target attribute.'
					
					INSERT INTO [metadata].[Attributes]
						(
						[AttributeName],
						[DataType],
						[ObjectId]
						)
					VALUES
						( 
						@TargetAttribute,
						@TargetDataType,
						@NewTargetObject
						)

					SET @NewTargetAttribute = SCOPE_IDENTITY()
				END
			ELSE
				BEGIN
					RAISERROR('Target attribute does not exist.',16,1);
					RETURN;
				END
		END
		ELSE
		BEGIN
			PRINT 'Found target attribute.'
			
			SELECT
				@NewTargetAttribute = [AttributeId]
			FROM
				[metadata].[Attributes]
			WHERE
				[AttributeName] = @TargetAttribute
				AND [ObjectId] = @NewTargetObject
		END


	---------------------------------------------------------------------------------------------
	--									final mapping insert
	---------------------------------------------------------------------------------------------
	INSERT INTO [metadata].[Mappings]
		( 
		[DataFlowId],
		[SourceSystemId],
		[SourceObjectId],
		[SourceAttributeId],
		[TargetSystemId],
		[TargetObjectId],
		[TargetAttributeId],
		[InUse]
		)
	VALUES
		(
		@NewDataFlow,
		@NewSourceSystem,
		@NewSourceObject, 
		@NewSourceAttribute, 
		@NewTargetSystem, 
		@NewTargetObject,
		@NewTargetAttribute,
		1
		)
	
	SET @NewMapping = SCOPE_IDENTITY()
	
	IF @Override = 1
	BEGIN
		PRINT 'Mapping added, double check system technology and object type settings.'
	END

	SELECT * FROM [metadata].[CompleteMappings] WHERE [MappingId] = @NewMapping

END
GO
