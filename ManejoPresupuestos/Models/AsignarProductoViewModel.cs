using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class AsignarProductoViewModel
    {

        public int RecetaId { get; set; }
        public int ProductoId { get; set; }
        public string Nombre { get; set; }
        public string Tiempo { get; set; }
    }
}
