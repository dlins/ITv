<?php
/*
 * @version $Id: dropdown.common.form.php 12404 2010-09-14 07:13:08Z moyo $
 -------------------------------------------------------------------------
 GLPI - Gestionnaire Libre de Parc Informatique
 Copyright (C) 2003-2010 by the INDEPNET Development Team.

 http://indepnet.net/   http://glpi-project.org
 -------------------------------------------------------------------------

 LICENSE

 This file is part of GLPI.

 GLPI is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 GLPI is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with GLPI; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 --------------------------------------------------------------------------
 */

// ----------------------------------------------------------------------
// Original Author of file: Remi Collet
// Purpose of file:
// ----------------------------------------------------------------------


if (!($dropdown instanceof CommonDropdown)) {
   displayErrorAndDie('');
}
if (!$dropdown->canView()) {
   displayRightError();
}


if (isset($_POST["id"])) {
   $_GET["id"] = $_POST["id"];
} else if (!isset($_GET["id"])) {
   $_GET["id"] = -1;
}


if (isset($_POST["add"])) {
   $dropdown->check(-1,'w',$_POST);

   if ($newID=$dropdown->add($_POST)) {
      $dropdown->refreshParentInfos();
      if ($dropdown instanceof CommonDevice) {
         Event::log($newID, get_class($dropdown), 4, "inventory",
                    $_SESSION["glpiname"]." ".$LANG['log'][20]." ".$_POST["designation"].".");
      } else {
         Event::log($newID, get_class($dropdown), 4, "setup",$_SESSION["glpiname"]." added ".$_POST["name"].".");
      }
   }

   // included by daniel@itvision.com.br
   // Se a operacao for a inclusão de uma entidade, executa externals.sh
   if ($dropdown instanceof Entity) {
      exec("/usr/local/itvision/scr/externals.sh ENTITY_ADD ". $newID);
      exec("echo ENTITY_ADD ". $newID." >> /usr/local/itvision/scr/entity.queue");
   }

   glpi_header($_SERVER['HTTP_REFERER']);

} else if (isset($_POST["delete"])) {
   $dropdown->check($_POST["id"],'w');
   if ($dropdown->isUsed() && empty($_POST["forcedelete"])) {
      commonHeader($dropdown->getTypeName(),$_SERVER['PHP_SELF'],"config","dropdowns",
                   str_replace('glpi_','',$dropdown->getTable()));
      $dropdown->showDeleteConfirmForm($_SERVER['PHP_SELF']);
      commonFooter();
   } else {
      // included by daniel@itvision.com.br
      // Se a operacao for a delecao de uma entidade, executa externals.sh
      if ($dropdown instanceof Entity) {
         exec("/usr/local/itvision/scr/externals.sh ENTITY_DELETE ". $_POST["id"]);
         exec("echo ENTITY_DELETE ". $_POST["id"]." >> /usr/local/itvision/scr/entity.queue");
      }

      $dropdown->delete($_POST, 1);
      $dropdown->refreshParentInfos();

      Event::log($_POST["id"], get_class($dropdown), 4, "setup", $_SESSION["glpiname"]." ".$LANG['log'][22]);
      glpi_header($dropdown->getSearchURL());
   }

} else if (isset($_POST["replace"])) {
   // included by daniel@itvision.com.br
   // Se a operacao for a replace de uma entidade, executa externals.sh
   if ($dropdown instanceof Entity) {
      exec("/usr/local/itvision/scr/externals.sh ENTITY_REPLACE ". $_POST["id"]." ". $_POST["_replace_by"]);
      exec("echo ENTITY_REPLACE ". $_POST["id"]." ". $_POST["_replace_by"]." >> /usr/local/itvision/scr/entity.queue");
   }

   $dropdown->check($_POST["id"],'w');
   $dropdown->delete($_POST, 1);
   $dropdown->refreshParentInfos();

   Event::log($_POST["id"], get_class($dropdown), 4, "setup", $_SESSION["glpiname"]." ".$LANG['log'][22]);
   glpi_header($dropdown->getSearchURL());

} else if (isset($_POST["update"])) {
   $dropdown->check($_POST["id"],'w');
   $dropdown->update($_POST);
   $dropdown->refreshParentInfos();

   // included by daniel@itvision.com.br
   // Se a operacao for a update de uma entidade, executa externals.sh
   if ($dropdown instanceof Entity) {
      exec("/usr/local/itvision/scr/externals.sh ENTITY_UPDATE ". $_POST["id"]." ". $_POST["entities_id"]);
      exec("echo ENTITY_UPDATE ". $_POST["id"]." ". $_POST["entities_id"]." >> /usr/local/itvision/scr/entity.queue");
   }

   Event::log($_POST["id"], get_class($dropdown), 4, "setup", $_SESSION["glpiname"]." ".$LANG['log'][21]);
   glpi_header($_SERVER['HTTP_REFERER']);

} else if (isset($_POST["execute"])) {
   if (method_exists($dropdown, $_POST["_method"])) {
      call_user_func(array(&$dropdown,$_POST["_method"]),$_POST);
      glpi_header($_SERVER['HTTP_REFERER']);
   } else {
      displayErrorAndDie($LANG['common'][24]);
   }

} else if (isset($_GET['popup'])) {
   popHeader($dropdown->getTypeName(),$_SERVER['PHP_SELF']);
   if (isset($_GET["rand"])) {
      $_SESSION["glpipopup"]["rand"]=$_GET["rand"];
   }
   $dropdown->showForm($_GET["id"]);
   echo "<div class='center'><br><a href='javascript:window.close()'>".$LANG['buttons'][13]."</a>";
   echo "</div>";
   popFooter();

} else {
   $dropdown->displayHeader();
   $dropdown->showForm($_GET["id"]);
   commonFooter();
}

?>
