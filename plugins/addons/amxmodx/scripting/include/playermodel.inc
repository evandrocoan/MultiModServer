#if defined _playermodel_included
  #endinput
#endif
#define _playermodel_included

#pragma reqlib playermodel

native fm_set_user_model(index, const model[], bool:bSetModelIndex);

native fm_reset_user_model(index);

stock get_user_model(index, model[], len)
{
	return get_user_info(index, "model", model, len);
}