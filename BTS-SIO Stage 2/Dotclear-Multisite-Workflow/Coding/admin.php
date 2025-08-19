<!DOCTYPE html>
<?php
	$hostname = "localhost";
	$username = "dotclearuser";
	$password = "cleardotstage";
	$database = "dotclear";
	$sql_connect = new MySQLi($hostname, $username, $password, $database);

function securite_bdd($string)
{
	if(ctype_digit($string))
	{
		$string = intval($string);
	}
	else
	{
		$string = addcslashes($string, '%_');
		$string = stripslashes($string);
		$string = strip_tags($string);
		$string = trim($string," ");
		$string = implode("",explode("\\",$string));
		$string = filter_var($string ,FILTER_SANITIZE_STRING, FILTER_FLAG_STRIP_LOW | FILTER_FLAG_STRIP_HIGH);
	}
	return stripslashes(trim($string));
}
?>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Panel Admin - Gestion des demandes de blog</title>
		<link rel='stylesheet' type='text/css' href="admin.css" />
	</head>
	<body>		
		<?php
    $reqselect = "SELECT * FROM dc_demands;";
    $resultselect = mysqli_query($sql_connect, $reqselect);
    $numresult = mysqli_num_rows($resultselect);
                             
if(mysqli_num_rows($resultselect) > 0) {
?>
<div id="corps_vues">
    <div id="resultat_agent">
        <table id = "absolute_table" bgcolor = black>
            <thead>
                <tr id = "titre_colonne">
                    <th width=149 nowrap bgcolor="#008E8E">ID Demandeur</th>
                    <th width=149 nowrap bgcolor="#008E8E">Nom</th>
                    <th width=149 nowrap bgcolor="#008E8E">Prénom</th>
                    <th width=149 nowrap bgcolor="#008E8E">Association</th>
                    <th width=149 nowrap bgcolor="#008E8E">Adresse</th>
                    <th width=149 nowrap bgcolor="#008E8E">Téléphone</th>
                    <th width=149 nowrap bgcolor="#008E8E">Nom de Domaine</th>
                    <th width=149 nowrap bgcolor="#008E8E">Déclaration</th>
                    <th width=149 nowrap bgcolor="#008E8E">Validé</th>
                    <th width=149 nowrap bgcolor="#008E8E">Date de la demande</th>
                </tr>
            </thead>
        </table>
		<table>
		<tbody>
<?php
while($rowsel = mysqli_fetch_array($resultselect,MYSQLI_ASSOC)) {
    echo '<tr>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["id_demand"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["name"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["Subname"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["Association"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["Adress"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["Telephone"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["Domain"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["Declaration"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["Validated"].'</td>';
    echo '<td bgcolor="#EFEFEF">'.$rowsel["date"].'</td>';
    echo '</tr>'."\n";}

    echo '</tbody>';
    echo '</table>'."\n";}
else {
	echo 'Pas d\'enregistrements dans cette table...';
	}
?>
</div>
</div>
	</body>
</html>