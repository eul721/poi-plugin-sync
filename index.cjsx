{_, $, $$, React, ReactBootstrap, FontAwesome, layout, i18n, ipc, remote} = window
{Grid, Row, Col, Tabs, Tab, ListGroup, ListGroupItem, Panel, OverlayTrigger, Tooltip, Button, Input} = ReactBootstrap

s3 = require 's3'
awsS3Client = s3.createClient
  s3Options:
    accessKeyId: config.get 'plugin.sync.aak'
    secretAccessKey: config.get 'plugin.sync.asak'
    region: "us-west-2"



module.exports =
  name: 'Sync'
  displayName: 'Sync Module'
  reactClass: React.createClass
    getInitialState: ->
      {
        path : config.get 'plugin.sync.wheremyfuelpath' || ''
        aak : config.get 'plugin.sync.aak' || ''
        asak : config.get 'plugin.sync.asak' || ''
      }

    setConfigs: () ->
      path = @state.path
      aak = @state.aak
      asak = @state.asak
      config.set 'plugin.sync.wheremyfuelpath',path
      config.set 'plugin.sync.aak',aak
      config.set 'plugin.sync.asak',asak
      awsS3Client = s3.createClient
        s3Options:
          accessKeyId: aak
          secretAccessKey: asak
          region: "us-west-2"
    changedInput: () ->
      @setState {
        path: @refs.path.getValue(),
        aak: @refs.aak.getValue(),
        asak: @refs.asak.getValue(),

      }
    syncConfigs: () ->
      params =
        localDir : @state.path
        s3Params :
          Bucket : 'poi-sync-configs'
          Prefix : 'wheres-my-fuel-gone'
      downloader = awsS3Client.downloadDir params
      downloader.on 'error', (error) ->
        console.log( error.stack)
        window.error ('There were some errors. Please check the inspector for more details.')
      downloader.on 'progress', () ->
        window.log do
        (current = downloader.progressAmount, total = downloader.progressTotal) ->
          "Current Progress: #{current}/#{total}"
      downloader.on 'end', (error) ->
        window.log 'Done.'
    uploadConfigs: () ->
      params =
        localDir : @state.path
        s3Params :
          Bucket : 'poi-sync-configs'
          Prefix : 'wheres-my-fuel-gone'
      uploader = awsS3Client.uploadDir params
      uploader.on 'error', (error) ->
        console.log( error.stack)
        window.error ('There were some errors. Please check the inspector for more details.')
      uploader.on 'progress', () ->
        window.log do
        (current = uploader.progressAmount, total = uploader.progressTotal) ->
          "Current Progress: #{current}/#{total}"
      uploader.on 'end', () ->
        window.log 'Done.'


    render: ->
      <Grid>
        <Row>
          <Col xs={12}>
            <Input
              type="text"
              value={@state.path}
              placeholder="Enter text"
              label="Config Path"
              help="Path to the config file"
              ref="path"
              onChange={@changedInput} />
            <Input
              type="text"
              value={@state.aak}
              placeholder="Enter text"
              label="AWS Access Key"
              ref="aak"
              onChange={@changedInput} />
            <Input
              type="password"
              value={@state.asak}
              placeholder="Enter text"
              label="AWS Secret Access Key"
              ref="asak"
              onChange={@changedInput} />
            <Button onClick={@setConfigs}>Set Configs</Button>
            <Button onClick={@syncConfigs}>Sync Configs</Button>
            <Button onClick={@uploadConfigs}>Upload Configs</Button>
          </Col>
        </Row>
      </Grid>
