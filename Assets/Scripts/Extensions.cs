using System.Collections.Generic;
using System.Text;
using UnityEngine;

public static class Extensions
{
    public static string MergeAsString<T>(this IList<T> list, string separator = "\n", bool ignoreEmptyEntries = true)
    {
        StringBuilder sb = new StringBuilder();

        for (int i = 0; i < list.Count; i++)
        {
            if (ignoreEmptyEntries && string.IsNullOrEmpty(list[i].ToString()))
            {
                continue;
            }

            if (sb.Length > 0)
            {
                sb.Append(separator);
            }

            sb.Append(list[i]);
        }

        return sb.ToString();
    }
}
